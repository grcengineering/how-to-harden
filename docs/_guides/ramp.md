---
layout: guide
title: "Ramp Hardening Guide"
vendor: "Ramp"
slug: "ramp"
tier: "2"
category: "HR/Finance"
description: "Harden Ramp identity, roles, integrations, AI connections, financial approval policies, card data, and audit collection with documented controls and reviewable Code Packs."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-08"
---

## Overview

Ramp combines corporate cards, expenses, procurement, Bill Pay, and business banking in a financial control plane. Compromise of a user, integration, or approval policy can expose financial records or authorize spending. This guide focuses on controls a customer can configure, with explicit limits on what an API inventory proves.

**Placement:** Ramp Business Corporation → standalone Ramp guide. The [official security site](https://ramp.com/security) identifies the company and links its Trust Center. No other Ramp-owned guide exists in this checkout.

### Intended Audience

- Security engineers and identity administrators
- Ramp administrators and finance operations owners
- Integration developers and GRC reviewers

### How to Use This Guide

- **L1 (Crawl):** Identity, least privilege, basic financial safeguards, and audit evidence.
- **L2 (Walk):** More restrictive integration, data, and independent approval controls.
- **L3 (Run):** Banking policy governance and specialized card-data integrations where applicable.
- Apply changes first to a controlled test account or sandbox. Never use a live payment to test an approval control.
- API/CLI packs are read-only, the browser policy is an opt-in configuration recipe, and the Sigma rule is a detection template. Inventory results are not a tenant-wide compliance score.

### Scope

Commercial Ramp business administration, supported identity provisioning, Developer API, first-party CLI/MCP access, connected accounting/receipt services, financial authorization policies, and audit events. Geography, plan, enabled products, and rollout flags can affect applicability. Banking/card integration sections do not instruct readers to open accounts, invest, issue cards, or execute payments. Ramp states that it is not HIPAA compliant and must not hold or process ePHI; keep patient-identifiable information out of the platform.

The rendered Trust Center catalog was inspected across All, Public, and Private filters: 19 listed documents, including 17 private documents whose contents remain unverified. Public Product Security guidance was read and reconciled below. RampGov is explicitly a distinct offering limited to Corporate Card and Expense Management; its FedRAMP Ready, GovRAMP Ready, and TX-RAMP Provisional statuses do not transfer to commercial Ramp. This is **not** comprehensive coverage of private documents. Details, source-derived candidates, automation evidence, and remaining gaps are in the [source coverage ledger](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/ramp-source-coverage.md). Native IP-allowlist configuration, admin strict-MFA navigation, and session timeout policy remain unverified; no invented toggle or endpoint is supplied.

**Validation boundary:** No tenant or credentials were supplied. Documentation review, schema checks, mocked API/CLI tests, and rendering checks are not live product validation. See the [validation record](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/ramp-validation.md) and [maturity definitions](https://github.com/grcengineering/how-to-harden/blob/main/VERSIONS.md#maturity-statuses--the-matrix).

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [OAuth & Integration Security](#2-oauth--integration-security)
3. [Financial Authorization Safeguards](#3-financial-authorization-safeguards)
4. [Data Security](#4-data-security)
5. [Monitoring & Detection](#5-monitoring--detection)
6. [Compliance Quick Reference](#6-compliance-quick-reference)

## 1. Authentication & Access Controls

### 1.1 Require SAML SSO and Review Exceptions

**Profile Level:** L1 (Crawl)

| Framework | Reference |
|-----------|-----------|
| CIS Controls v8 | 6.3 Require MFA for Externally-Exposed Applications |
| NIST SP 800-53 Rev. 5 | IA-2 Identification and Authentication |

#### Description

Use the corporate identity provider for workforce authentication and require strong MFA in that provider. Remove unnecessary alternate sign-in methods only after testing SAML and an independent recovery procedure.

#### Rationale

**Why This Matters:**

- Central identity policy reduces password reuse and orphaned access.
- A password exception or Guest account remains a separate authentication path.

**Attack Prevented:** Credential stuffing and bypass of corporate identity policy.

#### Prerequisites

Ramp Administrator or IT Admin; an eligible IdP account and verified company email domains. Keep a second working administrator session during rollout.

#### ClickOps Implementation

1. Open **Company security > Account access > Configure** and configure the SAML provider with its documented wizard. Supply the required first name, last name, and email attributes.
2. Test from the Ramp sign-in page with a pilot user in each domain. Ramp supports SP-initiated SAML, not an IdP-initiated SAML launch.
3. In **Login methods > User roles**, retain SAML for workforce roles and remove Password/Google SSO where not required. Every role needs at least one method. Review the **Exceptions** tab and document each retained exception.
4. Apply phishing-resistant MFA and appropriate device/access policy in the IdP. Ramp does not add native sign-in MFA after SAML. Guest password sign-in cannot be disabled.

**Source:** [SSO and login controls](https://support.ramp.com/setting-up-single-sign-on-sso-and-login-controls-in-ramp/), [exceptions](https://support.ramp.com/managing-login-controls-in-ramp/), [SAML troubleshooting](https://support.ramp.com/troubleshooting-sso-sign-in-issues/) (checked 2026-11-08).

**Automation:** ClickOps configuration. No matching configuration write/read endpoint was found in the [reviewed public OpenAPI catalog](https://docs.ramp.com/openapi/developer-api.json) on 2026-11-08. The [surface census](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/ramp-source-coverage.md#automation-surface-census) records the bounded API result and the distinct CLI, Alpha SDK, and unverified partner capabilities; it is not a claim of global absence.

#### Validation & Testing

1. Test allowed and disallowed methods for each role and domain using nonprivileged test users.
2. Confirm the IdP actually challenges for MFA. Record recovery contacts; an SSO-locked admin must use Ramp Support, not an assumed bypass URL.

#### Compliance Mappings

| Framework | Control | Relationship |
|-----------|---------|--------------|
| CIS Controls v8 | 6.3 Require MFA for Externally-Exposed Applications | Supports the control objective; evaluate the full safeguard separately. |
| NIST SP 800-53 Rev. 5 | IA-2 Identification and Authentication | Customer configuration/evidence contributes to this requirement. |

### 1.2 Strengthen MFA and Enroll Passkeys

**Profile Level:** L1 (Crawl)

| Framework | Reference |
|-----------|-----------|
| CIS Controls v8 | 6.5 Require MFA for Administrative Access |
| NIST SP 800-53 Rev. 5 | IA-2 Identification and Authentication |

#### Description

For users with permitted local sign-in, enroll passkeys and an authenticator app. Preserve a distinct working verification method for sensitive-action step-up; enrollment does not establish a company-wide passkey mandate.

#### Rationale

**Why This Matters:**

- Passkeys resist phishing of reusable passwords.
- An authenticator app reduces dependence on phone delivery, while a separate recovery method limits lockout.

**Attack Prevented:** Password phishing and interception of weaker verification channels.

#### Prerequisites

Individual user access to Ramp web settings and a supported authenticator. Establish recovery before removing any method.

#### ClickOps Implementation

1. Open **Personal security > Configure a passkey** (or **Add passkey**) and enroll a supported device or security key. Name it so it can be recognized during review.
2. Open the authenticator settings linked from the MFA documentation and choose **Set up authenticator** or **Add authenticator**. Complete enrollment without sharing the enrollment secret.
3. Review registered methods and remove an obsolete credential only after another works. Keep another MFA method for step-up; a second passkey is not a different method.
4. Ask the administrator to review strict MFA fallback restrictions. The public article describes their behavior but does not supply an exact admin toggle path; verify that path with Ramp before changing it.

**Source:** [MFA overview](https://support.ramp.com/multi-factor-authentication-mfa-overview/), [passkeys](https://support.ramp.com/logging-in-with-passkeys/) (checked 2026-11-08).

**Automation:** ClickOps configuration. No matching configuration write/read endpoint was found in the [reviewed public OpenAPI catalog](https://docs.ramp.com/openapi/developer-api.json) on 2026-11-08. The [surface census](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/ramp-source-coverage.md#automation-surface-census) records the bounded API result and the distinct CLI, Alpha SDK, and unverified partner capabilities; it is not a claim of global absence.

#### Validation & Testing

1. Test a permitted passkey login and a sensitive-action verification prompt without executing a financial action.
2. Document that password on an untrusted device triggers MFA, Google SSO is conditional, and SAML MFA belongs to the IdP. Do not mark the tenant passkey-enforced from one enrollment.

#### Compliance Mappings

| Framework | Control | Relationship |
|-----------|---------|--------------|
| CIS Controls v8 | 6.5 Require MFA for Administrative Access | Supports the control objective; evaluate the full safeguard separately. |
| NIST SP 800-53 Rev. 5 | IA-2 Identification and Authentication | Customer configuration/evidence contributes to this requirement. |

### 1.3 Minimize Roles and Privileges

**Profile Level:** L1 (Crawl)

| Framework | Reference |
|-----------|-----------|
| CIS Controls v8 | 6 Access Control Management |
| NIST SP 800-53 Rev. 5 | AC-6 Least Privilege |

#### Description

Assign the narrowest base and additional roles needed. Review role definitions and user assignments together, because Ramp combines granted permissions rather than subtracting one role from another.

#### Rationale

**Why This Matters:**

- Broad finance and integration permissions enlarge the impact of a compromised identity.
- A custom role does not remove privileges already granted by a base role.

**Attack Prevented:** Privilege abuse and unauthorized changes to users, integrations, or financial settings.

#### Prerequisites

Administrator access. Ramp Plus is required for role customization and custom roles.

#### ClickOps Implementation

1. Review **Company > People** and each user's assigned roles. Separate IT administration from finance administration wherever practical.
2. Open **Company > Settings > User roles** (also described as **Settings > Roles and permissions**). Review integration administration, user management, bank-data visibility, payment details, and approval-policy editing.
3. Disable unnecessary customizable permissions and select **Save changes**. Implied permissions cannot be toggled; choose a less privileged role if those permissions are excessive.
4. Use a Custom Role for a distinct permission set. Check all additional roles and preserve sufficient independent administrators.

**Source:** [Role overview](https://support.ramp.com/user-roles-overview/), [role customization](https://support.ramp.com/customizing-roles-and-permissions/), [custom roles](https://support.ramp.com/creating-a-custom-role/) (checked 2026-11-08).

#### Code Implementation

{% include pack-code.html vendor="ramp" section="1.3" %}

#### Validation & Testing

1. Test a low-privilege user against both an allowed operation and a forbidden administrative operation.
2. The 1.3 API inventory excludes suspended users (use 1.4 for those) and lists base roles and custom-role definitions, not each user's complete effective permissions. Reconcile additional-role assignments in the UI before approving access.

#### Compliance Mappings

| Framework | Control | Relationship |
|-----------|---------|--------------|
| CIS Controls v8 | 6 Access Control Management | Supports the control objective; evaluate the full safeguard separately. |
| NIST SP 800-53 Rev. 5 | AC-6 Least Privilege | Customer configuration/evidence contributes to this requirement. |

### 1.4 Reconcile Provisioning and Offboarding

**Profile Level:** L1 (Crawl)

| Framework | Reference |
|-----------|-----------|
| CIS Controls v8 | 5.3 Disable Dormant Accounts |
| NIST SP 800-53 Rev. 5 | AC-2 Account Management |

#### Description

Connect a supported SCIM provider and reconcile active, inactive, draft, and invited accounts against approved access. Treat deactivation, termination, and reassignment of approvals as separate steps.

#### Rationale

**Why This Matters:**

- Disabling sign-in alone is not a complete offboarding record.
- SCIM-managed fields can overwrite manual changes and restore an unintended assignment.

**Attack Prevented:** Orphaned access and spending through stale workforce identities.

#### Prerequisites

Ramp Admin and IdP administration for Okta, Microsoft Entra, or Rippling. Do not test offboarding on the current operator or a last administrator.

#### ClickOps Implementation

1. Open **Integrations**, select the supported identity provider, and follow its SCIM wizard. SCIM provisioning and SSO sign-in are separate integrations.
2. In **People**, open the connected provider settings and review last sync, errors, invite preferences, and offboarding behavior. Choose **Create profile only** when access should be staged rather than immediately invited.
3. Make durable identity/role changes in the IdP. Review manager mappings, which can confer Manager access.
4. Deactivate a controlled test user through the IdP. In Ramp, verify the inactive state and reassign workflow responsibilities. Review termination or auto-termination separately after business approval.

**Source:** [SCIM provisioning](https://support.ramp.com/setting-up-scim-and-managing-user-provisioning/), [deactivation](https://support.ramp.com/deactivating-and-removing-users-from-ramp/), [API lifecycle](https://docs.ramp.com/developer-api/v1/user-lifecycle) (checked 2026-11-08).

#### Code Implementation

{% include pack-code.html vendor="ramp" section="1.4" %}

#### Validation & Testing

1. Confirm the test user cannot sign in or spend. Deactivation does not terminate existing cards/funds or remove workflow assignments; reactivation restores access and spend.
2. Compare the read-only inventory to the authoritative roster and investigate sync errors. API PATCH deactivation exists, but this pack intentionally does not act without reliable caller/effective-privilege identification.

#### Compliance Mappings

| Framework | Control | Relationship |
|-----------|---------|--------------|
| CIS Controls v8 | 5.3 Disable Dormant Accounts | Supports the control objective; evaluate the full safeguard separately. |
| NIST SP 800-53 Rev. 5 | AC-2 Account Management | Customer configuration/evidence contributes to this requirement. |

### 1.5 Revoke Sessions and Test Recovery

**Profile Level:** L1 (Crawl)

| Framework | Reference |
|-----------|-----------|
| CIS Controls v8 | 6 Access Control Management |
| NIST SP 800-53 Rev. 5 | AC-12 Session Termination |

#### Description

Establish a session-revocation procedure independent of password changes. A connected Google password reset alone does not invalidate existing Ramp sessions.

#### Rationale

**Why This Matters:**

- An attacker may retain an already authenticated session.
- Recovery must be usable when an identity provider or primary credential is unavailable.

**Attack Prevented:** Continued access through stolen or abandoned sessions.

#### Prerequisites

A controlled test account and a second device/browser session. Do not sign out the sole administrative recovery session during an SSO change.

#### ClickOps Implementation

1. In the browser, open **Personal settings > Sign out everywhere** to revoke all active Ramp sessions when containment is required.
2. For a legitimate unfamiliar-login alert, use Ramp's account-protection flow. Password users can choose **Sign out and reset password**; Google users choose **Sign out everywhere** and address their Google credential separately.
3. Keep a verified Ramp Support recovery route and security contact. Login alerts are always-on for password/Google OAuth, but do not cover SAML, passkey, or email-OTP sign-ins.

**Source:** [Unified login](https://support.ramp.com/unified-login/), [sign-in notifications](https://support.ramp.com/new-sign-in-notifications/), [Trust Center Login History](https://trust.ramp.com/?itemName=product_features&source=click) (checked 2026-11-08).

**Automation:** ClickOps configuration. No matching configuration write/read endpoint was found in the [reviewed public OpenAPI catalog](https://docs.ramp.com/openapi/developer-api.json) on 2026-11-08. The [surface census](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/ramp-source-coverage.md#automation-surface-census) records the bounded API result and the distinct CLI, Alpha SDK, and unverified partner capabilities; it is not a claim of global absence.

#### Validation & Testing

1. With a test account, confirm that both existing sessions require fresh authentication after revocation.
2. Review **Personal settings > Security > Login history** for the documented last 30 days, and use IdP logs plus Ramp audit events for SAML coverage. This history is not enterprise audit retention; absence of a sign-in email is not evidence of no access.

#### Compliance Mappings

| Framework | Control | Relationship |
|-----------|---------|--------------|
| CIS Controls v8 | 6 Access Control Management | Supports the control objective; evaluate the full safeguard separately. |
| NIST SP 800-53 Rev. 5 | AC-12 Session Termination | Customer configuration/evidence contributes to this requirement. |

### 1.6 Expire Guest Access Deliberately

**Profile Level:** L2 (Walk)

| Framework | Reference |
|-----------|-----------|
| CIS Controls v8 | 5 Account Management |
| NIST SP 800-53 Rev. 5 | AC-2 Account Management |

#### Description

Use Guest for time-limited external access and explicitly review the deactivation date and issued spend. Do not rely on every import path to supply an expiration.

#### Rationale

**Why This Matters:**

- External accounts may remain outside the workforce IdP.
- An optional blank expiration can turn temporary access into indefinite access.

**Attack Prevented:** Abuse of forgotten contractor or guest access.

#### Prerequisites

Ramp Plus and permission to manage users. Review guest need and sponsor before modifying access.

#### ClickOps Implementation

1. In **Company > People**, review Guest users and their profile expiration/scheduled deactivation dates. Set an approved end date during invitation or user editing.
2. Inspect CSV imports for **deactivation_date**. UI and Developer API guest invitations normally default to six months; CSV and Dashboard API paths do not pre-fill it.
3. Review cards/funds issued by an administrator and retain only the approved purpose. Guest cannot approve requests, but can spend on authorized issued resources.

**Source:** [Guest role and expiration](https://support.ramp.com/user-role-deep-dive-guest/), [API user lifecycle](https://docs.ramp.com/developer-api/v1/user-lifecycle) (checked 2026-11-08).

**Automation:** Read verification is provided by the user inventory in control 1.4. Scheduled deactivation writes are documented in the Users API but are not automated here because account ownership and additive privileges require operator review.

#### Validation & Testing

1. Verify every active Guest has a sponsor and explicit end-date decision.
2. Confirm an expired test Guest becomes inactive, not automatically terminated. Check the separate password exception inherent to Guest in control 1.1.

#### Compliance Mappings

| Framework | Control | Relationship |
|-----------|---------|--------------|
| CIS Controls v8 | 5 Account Management | Supports the control objective; evaluate the full safeguard separately. |
| NIST SP 800-53 Rev. 5 | AC-2 Account Management | Customer configuration/evidence contributes to this requirement. |

## 2. OAuth & Integration Security

### 2.1 Limit Developer API Authorization

**Profile Level:** L1 (Crawl)

| Framework | Reference |
|-----------|-----------|
| CIS Controls v8 | 6.8 Define and Maintain Role-Based Access Control |
| NIST SP 800-53 Rev. 5 | AC-6 Least Privilege |

#### Description

Use separate integration applications with only the scopes required by their task. Treat a client-credentials token as business-wide within those scopes, not as a human user with a narrow department role.

#### Rationale

**Why This Matters:**

- A stolen integration token can cross user boundaries.
- Read-only scopes still permit extraction of the data they authorize.

**Attack Prevented:** Excessive OAuth access and integration-token misuse.

#### Prerequisites

Authorized business Admin/Owner and an approved integration design. Creating credentials or expanding access requires explicit organizational approval.

#### ClickOps Implementation

1. Open **Settings > Developer** through the Developer Console linked in Ramp's authorization guide. Inventory each app's owner, environment, grant type, redirect URIs, and granted scopes.
2. Remove unjustified write capabilities and avoid **cards:read_vault** except for an approved server-side card integration. Request specific scopes when issuing a token; omitted scope does not mean safe default access.
3. For authorization-code apps, validate unpredictable state against the original session and use an exact registered HTTPS callback. Keep client secrets on the server.
4. Store credentials in a secret manager and use response expiry rather than assuming a uniform lifetime. Keep production and sandbox apps separate.

**Source:** [Authorization and credential safety](https://docs.ramp.com/developer-api/v1/authorization), [Developer API quickstart](https://docs.ramp.com/developer-api/v1/getting-started) (checked 2026-11-08).

**Automation:** Console configuration plus documented OAuth token APIs. No app-policy inventory/write endpoint is present in the reviewed public OpenAPI schema. Packs consume an existing scoped token; they do not create credentials, expand grants, or claim to prove the entire grant set.

#### Validation & Testing

1. In an authorized sandbox, confirm a read-only token can read its intended resource and that an unrelated operation is denied. Do not test with a production payment.
2. Record a scope inventory without recording tokens. MCP/CLI permissions are a different model, covered in 2.2.

#### Compliance Mappings

| Framework | Control | Relationship |
|-----------|---------|--------------|
| CIS Controls v8 | 6.8 Define and Maintain Role-Based Access Control | Supports the control objective; evaluate the full safeguard separately. |
| NIST SP 800-53 Rev. 5 | AC-6 Least Privilege | Customer configuration/evidence contributes to this requirement. |

### 2.2 Restrict AI Connections and CLI Access

**Profile Level:** L2 (Walk)

| Framework | Reference |
|-----------|-----------|
| CIS Controls v8 | 6 Access Control Management |
| NIST SP 800-53 Rev. 5 | AC-6 Least Privilege |

#### Description

Permit only approved users to connect AI tools, and choose read-only access for analysis. Ramp MCP and CLI act with the connecting user's role; their current permission model is not Developer API scope selection.

#### Rationale

**Why This Matters:**

- An assistant connection can inherit powerful finance actions.
- A connection inventory is not necessarily a revocation console or complete tool-call audit.

**Attack Prevented:** Unapproved AI data access and excessive agent authority.

#### Prerequisites

Admin access for business controls; Ramp Plus for per-role permissions. CLI installed from Ramp's official release instructions only.

#### ClickOps Implementation

1. Open **Integrations > Ramp MCP > Manage access** and disable access or restrict it to approved users/teams.
2. On Plus, review **Settings > Roles and permissions > Manage connections to Ramp via MCP, CLI and other AI connectors**. Remove it from roles that do not need it.
3. Review **Settings > Developer > Connected AI tools** if enabled for the business. This page is read-only; do not promise a remove-connection button.
4. For an approved CLI connection choose **Read-only** at consent, or use the documented read-only login command in the pack README. Do not use the obsolete scope flag.
5. Review agentic payment authority separately: Agent Cards and Stripe MPP can act with the connected user’s existing permissions. Remove the custom-role capability **Make MPP payments using accessible funds** where unnecessary. Standalone agent identities are limited early access; do not create one solely for this audit.
6. Where standalone agents are already enabled, review each agent’s owner, custom-role assignments and active status separately from human MCP consent. Retire unneeded identities and rotate compromised credentials through the documented lifecycle workflow after authorization. The Alpha SDK exposes these operations; exact tenant UI and wallet-policy semantics remain unverified, so no mutation script is supplied.

**Source:** [Connected AI tools](https://support.ramp.com/managing-connected-ai-tools/), [CLI reference](https://docs.ramp.com/developer-api/v1/cli), [MCP](https://docs.ramp.com/developer-api/v1/ramp-mcp), [Agentic Payments permission and funding boundaries](https://docs.ramp.com/developer-api/v1/agent-payments), [Alpha SDK agent lifecycle reference](https://github.com/ramp-public/ramp-python/blob/21dcf421a7fa0754f77f4ca532ccbdd91f0db21b/src/ramp/_generated/agent_tools.py#L14899-L15067) (checked 2026-11-08).

#### Code Implementation

{% include pack-code.html vendor="ramp" section="2.2" %}

#### Validation & Testing

1. Use the CLI pack to inspect existing sign-in status and identity. It does not authenticate or change access.
2. Check an authorized read-only connection does not expose write tools. Monitor actual product changes as well as connection inventory; not every MCP call creates an audit event.
3. Verify approved agent connections have only the intended access. Agent Cards/MPP use eligible funds; x402 uses a separately funded wallet, so fund restrictions do not prove its payment limits. Do not fund a wallet or perform a purchase as a test.

#### Compliance Mappings

| Framework | Control | Relationship |
|-----------|---------|--------------|
| CIS Controls v8 | 6 Access Control Management | Supports the control objective; evaluate the full safeguard separately. |
| NIST SP 800-53 Rev. 5 | AC-6 Least Privilege | Customer configuration/evidence contributes to this requirement. |

### 2.3 Review Accounting Integrations

**Profile Level:** L1 (Crawl)

| Framework | Reference |
|-----------|-----------|
| CIS Controls v8 | 6 Access Control Management |
| NIST SP 800-53 Rev. 5 | AC-6 Least Privilege |

#### Description

Reconcile connected accounting systems, access owners, and the data each integration needs. Remove unnecessary integration-management permissions before allowing additional connectors.

#### Rationale

**Why This Matters:**

- Accounting integrations carry broad business information across trust boundaries.
- An old or failed connection can hide unowned credentials and unexpected data paths.

**Attack Prevented:** Supply-chain compromise through excessive or abandoned ERP access.

#### Prerequisites

Permission to manage accounting integrations; existing token with accounting:read for the optional inventory.

#### ClickOps Implementation

1. Open **Integrations** and inspect the configured accounting provider using its provider-specific management screen. Verify that the connected organization and responsible owner are correct.
2. Review **Company > Settings > User roles** and limit the permission to connect/disconnect accounting integrations.
3. For a retired integration, follow its documented disconnect procedure in both Ramp and the accounting provider. Preserve approved records before changing synchronization.

**Source:** [Accounting integrations](https://support.ramp.com/integrations/set-up-accounting-integrations/), [role permissions](https://support.ramp.com/customizing-roles-and-permissions/), [Accounting API](https://docs.ramp.com/developer-api/v1/api/accounting) (checked 2026-11-08).

#### Code Implementation

{% include pack-code.html vendor="ramp" section="2.3" %}

#### Validation & Testing

1. Reconcile the API's connection type, provider metadata, and active flag (is_active) to the UI. The current endpoint is **all-connections**, not the deprecated active-connection endpoint.
2. Review unexpected active connections in the inventory and failed authentication in the provider/Ramp UI. The pack omits deprecated status and does not prove the permission set granted inside the ERP.

#### Compliance Mappings

| Framework | Control | Relationship |
|-----------|---------|--------------|
| CIS Controls v8 | 6 Access Control Management | Supports the control objective; evaluate the full safeguard separately. |
| NIST SP 800-53 Rev. 5 | AC-6 Least Privilege | Customer configuration/evidence contributes to this requirement. |

### 2.4 Minimize Receipt Collection Access

**Profile Level:** L2 (Walk)

| Framework | Reference |
|-----------|-----------|
| CIS Controls v8 | 3.3 Configure Data Access Control Lists |
| NIST SP 800-53 Rev. 5 | AC-4 Information Flow Enforcement |

#### Description

Approve mailbox, merchant, and automatic receipt collection independently. Disabling an individual-mailbox feature does not disable an existing company-wide email integration.

#### Rationale

**Why This Matters:**

- Receipt automation can read email or hold merchant credentials.
- Different collection paths have different revocation and data-sharing behavior.

**Attack Prevented:** Unnecessary third-party mailbox access and merchant-credential exposure.

#### Prerequisites

Admin access for company settings and individual user access for personal merchant credentials.

#### ClickOps Implementation

1. Open **Company > Integrations > Gmail or Outlook > Individual Inboxes**. Turn off **Allow employee mailbox access** when not approved, or exclude specific employees. Review the company-wide integration separately.
2. A user can open **Email connections**, select the inbox menu, and choose **Remove account**. Previously attached receipts remain.
3. If automatic merchant receipt sharing is not approved, open **Policy > Travel & expenses > Additional controls > Expense requirements** and turn off **Automatically collect receipts**.
4. For merchant credentials, use **Settings > Connectors > Merchant receipt collection > Remove credentials**. This is distinct from the browser extension, whose documented receipt scripts use the local merchant session.

**Source:** [Employee mailbox integration](https://support.ramp.com/employee-mailbox-integration/), [receipt auto-capture](https://support.ramp.com/receipt-auto-capture/), [extension security brief](https://support.ramp.com/ramp-chrome-extension-receipt-fetching-security-brief/) (checked 2026-11-08).

**Automation:** ClickOps for these business-wide controls. The public API has receipt-integration per-email opt-out endpoints, but they are not documented as equivalent to disabling mailbox access or deleting merchant credentials. No misleading equivalence pack is supplied.

#### Validation & Testing

1. Verify removed individual inbox connections are gone and check whether company-wide capture remains active.
2. Record which collection paths are approved and test with a nonsensitive receipt. Do not assume disabling collection deletes existing receipts or removes separately stored merchant credentials.

#### Compliance Mappings

| Framework | Control | Relationship |
|-----------|---------|--------------|
| CIS Controls v8 | 3.3 Configure Data Access Control Lists | Supports the control objective; evaluate the full safeguard separately. |
| NIST SP 800-53 Rev. 5 | AC-4 Information Flow Enforcement | Customer configuration/evidence contributes to this requirement. |

### 2.5 Authenticate Webhook Deliveries

**Profile Level:** L2 (Walk)

| Framework | Reference |
|-----------|-----------|
| CIS Controls v8 | 16 Application Software Security |
| NIST SP 800-53 Rev. 5 | SI-10 Information Input Validation |

#### Description

Validate the Ramp signature over the exact request bytes before processing events. Review subscription destinations and use durable event-ID deduplication rather than treating a valid signature as proof that an event is new.

#### Rationale

**Why This Matters:**

- Forged events can trigger downstream actions in financial systems.
- Ramp retries legitimate deliveries, so handlers must be idempotent.

**Attack Prevented:** Forged webhook events, payload alteration, and duplicate processing.

#### Prerequisites

An approved webhook receiver and securely stored subscription secret. Do not log secret values or sensitive payloads.

#### ClickOps Implementation

1. There is no verified native GUI for webhook signature enforcement. Configure it in the receiver using the official Webhooks reference; the API establishes and verifies subscriptions.
2. At the receiver, compare the **X-Ramp-Signature** HMAC-SHA256 with a constant-time comparison before parsing. Use the original raw bytes, not reserialized JSON.
3. Require HTTPS, bound request sizes, allow only expected event types/business context, and persist processed event IDs atomically. Deduplicate retries before executing side effects.
4. Review the subscription inventory for unapproved endpoint hosts and inactive/pending verification states. Do not create a new destination merely to run this audit.

**Source:** [Webhooks reference](https://docs.ramp.com/developer-api/v1/webhooks) (checked 2026-11-08).

#### Code Implementation

{% include pack-code.html vendor="ramp" section="2.5" %}

#### Validation & Testing

1. Test a valid signature, a changed body, a wrong/missing signature, and duplicate delivery in an isolated receiver test.
2. The inventory pack does not attest that a receiver validates signatures or has durable replay protection. Obtain receiver-side test evidence separately.

#### Compliance Mappings

| Framework | Control | Relationship |
|-----------|---------|--------------|
| CIS Controls v8 | 16 Application Software Security | Supports the control objective; evaluate the full safeguard separately. |
| NIST SP 800-53 Rev. 5 | SI-10 Information Input Validation | Customer configuration/evidence contributes to this requirement. |

### 2.6 Deploy Ramp Browser Phishing Protection

**Profile Level:** L2 (Walk)

| Framework | Reference |
|-----------|-----------|
| CIS Controls v8 | 9.4 Restrict Unnecessary or Unauthorized Browser and Email Client Extensions |
| NIST SP 800-53 Rev. 5 | SI-3 Malicious Code Protection |

#### Description

Use the official Ramp for Chrome extension on approved managed browsers to add Ramp-specific phishing protection. Review the extension permissions and telemetry consequences before selecting force-install.

#### Rationale

**Why This Matters:**

- Look-alike sign-in pages can steal financial-system credentials.
- A security extension also has browser access and must be governed as an installed client.

**Attack Prevented:** Credential theft through known Ramp phishing sites.

#### Prerequisites

An approved browser-extension policy and Chrome management for the target devices. Privacy review is required: force-install enables License Intelligence tracking by default; employees can opt out in extension settings.

#### ClickOps Implementation

1. For an individual approved installation, use the Chrome Web Store link in the official Ramp extension article and verify the publisher and extension ID **idefohglmnkliiadgfofeokcpjobdeik**.
2. For managed Chrome, open **Google Admin > Chrome browser > Apps & extensions > Users & browsers**, then select the intended OU or group. Choose **Add from Chrome Web Store**, find **Ramp for Chrome** from ramp.com, and verify that ID.
3. Choose the approved **Installation policy**, such as **Force install** or **Force install + pin to browser toolbar**, and save. Pilot the policy with a small group; have employees sign in to the extension. Do not deploy tracking without the organization's approval.
4. Document how to remove or relax the managed installation policy for rollback. Employees cannot uninstall a force-installed extension themselves.

**Source:** [Trust Center Product Security: Phishing Protection](https://trust.ramp.com/?itemName=product_features&source=click), [Ramp for Chrome](https://support.ramp.com/ramp-chrome-extension/), [managed installation](https://support.ramp.com/install-ramp-for-chrome-for-employees-in-google-admin/) (checked 2026-11-08).

This Code Pack is a **Google Chrome on Linux managed-policy JSON recipe**, not a Google Admin import. Read the [conversion, merge, privacy, pilot, and rollback instructions](https://github.com/grcengineering/how-to-harden/tree/main/packs/ramp#managed-chrome-deployment-control-26) before deploying.

#### Code Implementation

{% include pack-code.html vendor="ramp" section="2.6" %}

#### Validation & Testing

1. On a test device, confirm the intended extension ID, publisher, installation state, and sign-in. Inspect policy propagation rather than assuming an Admin console save reached every browser.
2. Review License Intelligence settings and communicated opt-out instructions. Do not visit a real phishing site to test; use a vendor-approved benign procedure. Phishing protection is documented behavior, not a separately verified enable switch.

#### Compliance Mappings

| Framework | Control | Relationship |
|-----------|---------|--------------|
| CIS Controls v8 | 9.4 Restrict Unnecessary or Unauthorized Browser and Email Client Extensions | Supports the control objective; evaluate the full safeguard separately. |
| NIST SP 800-53 Rev. 5 | SI-3 Malicious Code Protection | Customer configuration/evidence contributes to this requirement. |

## 3. Financial Authorization Safeguards

### 3.1 Constrain Card and Fund Spending

**Profile Level:** L1 (Crawl)

| Framework | Reference |
|-----------|-----------|
| CIS Controls v8 | 6 Access Control Management |
| NIST SP 800-53 Rev. 5 | AC-3 Access Enforcement |

#### Description

Limit each vendor or purpose to an approved budget, eligible merchants/categories, and a defined lifetime. Treat funds and shared membership as authorization objects, not only reporting labels.

#### Rationale

**Why This Matters:**

- A compromised vendor or card cannot freely spend beyond a well-chosen boundary.
- Shared funds and temporary overrides can undermine otherwise narrow card restrictions.

**Attack Prevented:** Unauthorized merchant charges and abuse of excessive spending authority.

#### Prerequisites

Admin or authorized spend manager; a sandbox/test fund for validation without real charges.

#### ClickOps Implementation

1. Open **Manage spend > Funds > Issued** and edit the relevant fund. Review owner, amount, frequency, sharing, and permitted spend types.
2. Under **Advanced > Spending controls and restrictions > Add restrictions**, select allowed merchants/categories when the purpose is known. Include each relevant merchant identity.
3. Set the intended start and **Lock on a certain date**, and a maximum expense amount where appropriate. Review temporary increases and shared members.
4. Keep approval policy attached to the purpose. Funds/card limits do not automatically constrain the separate x402 wallet payment path.

**Source:** [Card and fund controls](https://support.ramp.com/setting-up-controls-on-ramp-cards-and-funds/), [spend-control scope](https://docs.ramp.com/developer-api/v1/spend-controls) (checked 2026-11-08).

#### Code Implementation

{% include pack-code.html vendor="ramp" section="3.1" %}

#### Validation & Testing

1. Read the saved restrictions back from the UI and API inventory; verify expected fund and spend-program settings.
2. Use sandbox tests or historical decline evidence, not a live purchase, to validate disallowed merchants and limits. An inventory is not proof of transaction authorization behavior.
3. For agent-enabled workflows, inspect the funding method: eligible Agent Cards and MPP purchases use fund controls; x402 wallets are a different authority plane and are not assessed by this inventory.

#### Compliance Mappings

| Framework | Control | Relationship |
|-----------|---------|--------------|
| CIS Controls v8 | 6 Access Control Management | Supports the control objective; evaluate the full safeguard separately. |
| NIST SP 800-53 Rev. 5 | AC-3 Access Enforcement | Customer configuration/evidence contributes to this requirement. |

### 3.2 Require Independent Vendor Approvals

**Profile Level:** L1 (Crawl)

| Framework | Reference |
|-----------|-----------|
| CIS Controls v8 | 6 Access Control Management |
| NIST SP 800-53 Rev. 5 | AC-5 Separation of Duties |

#### Description

Require review for new vendors and sensitive changes, including bank details arriving from Vendor Network or information requests. Keep independent approvers available after self-approval removal.

#### Rationale

**Why This Matters:**

- A trusted vendor identity can be abused to redirect payments.
- An empty approval branch or sole fallback approver can defeat separation of duties.

**Attack Prevented:** Fraudulent vendor onboarding and unauthorized payment-detail changes.

#### Prerequisites

Vendor-approval administrator; Owner to change separation of duties. Confirm fallback approvers are active and independent.

#### ClickOps Implementation

1. Open **Vendors > Settings > New vendor approvals** and **Vendor edit approvals**. Enable the relevant requirements.
2. For edits, cover sensitive fields and the **Vendor Network** and **Information Request** update sources, alongside direct changes. Add independent reviewers and **Save workflow**.
3. As Owner, enable **Enforce separation of duties** independently for creation and edits under **Policy > Vendor management**. Review fallback groups; a sole eligible Owner may still approve their own request.

**Source:** [Vendor approvals](https://support.ramp.com/vendor-approvals/) (checked 2026-11-08).

**Automation:** ClickOps configuration. No matching configuration write/read endpoint was found in the [reviewed public OpenAPI catalog](https://docs.ramp.com/openapi/developer-api.json) on 2026-11-08. The [surface census](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/ramp-source-coverage.md#automation-surface-census) records the bounded API result and the distinct CLI, Alpha SDK, and unverified partner capabilities; it is not a claim of global absence.

#### Validation & Testing

1. Test future vendor creation and each covered edit source using a controlled vendor, without making a payment. Changes should remain pending until the required review.
2. Existing requests are not retroactively updated. Test the no-eligible-approver case; investigate any unexpected auto-approval.

#### Compliance Mappings

| Framework | Control | Relationship |
|-----------|---------|--------------|
| CIS Controls v8 | 6 Access Control Management | Supports the control objective; evaluate the full safeguard separately. |
| NIST SP 800-53 Rev. 5 | AC-5 Separation of Duties | Customer configuration/evidence contributes to this requirement. |

### 3.3 Review Vendor Network Auto-Updates

**Profile Level:** L2 (Walk)

| Framework | Reference |
|-----------|-----------|
| CIS Controls v8 | 3.3 Configure Data Access Control Lists |
| NIST SP 800-53 Rev. 5 | AC-4 Information Flow Enforcement |

#### Description

Disable automatic ACH-detail replacement when policy requires independent payment-detail review. Assess vendor sharing before connecting, since network connectivity changes the data and update paths.

#### Rationale

**Why This Matters:**

- Some verified-account replacements can bypass normal acceptance and vendor-edit approval.
- Disconnecting a vendor stops updates but preserves previously synchronized data.

**Attack Prevented:** Unreviewed payment redirection through a trusted network connection.

#### Prerequisites

Vendor-approval administrator and an approved decision on which suppliers should be connected.

#### ClickOps Implementation

1. Open **Vendors > Settings > Vendor Network updates** and turn off **Auto-approve ACH details from bank accounts verified by Ramp** if manual review is required.
2. Review **Invite vendors to Vendor Network by default** and disable automatic invitation when your process requires deliberate supplier onboarding.
3. Inspect a connected vendor's network card and selected shared details. To stop future updates, use **Edit > Vendor details > Danger zone > Disconnect from the Vendor Network**, after evaluating operational impact.

**Source:** [Vendor Network behavior and controls](https://support.ramp.com/ramp-vendor-network/) (checked 2026-11-08).

**Automation:** ClickOps configuration. No matching configuration write/read endpoint was found in the [reviewed public OpenAPI catalog](https://docs.ramp.com/openapi/developer-api.json) on 2026-11-08. The [surface census](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/ramp-source-coverage.md#automation-surface-census) records the bounded API result and the distinct CLI, Alpha SDK, and unverified partner capabilities; it is not a claim of global absence.

#### Validation & Testing

1. Confirm automatic replacement is disabled and sensitive updates enter the configured review path.
2. Record that connecting can expose shared bills before approval. Disconnection neither deletes the vendor nor removes saved payment/tax details.

#### Compliance Mappings

| Framework | Control | Relationship |
|-----------|---------|--------------|
| CIS Controls v8 | 3.3 Configure Data Access Control Lists | Supports the control objective; evaluate the full safeguard separately. |
| NIST SP 800-53 Rev. 5 | AC-4 Information Flow Enforcement | Customer configuration/evidence contributes to this requirement. |

### 3.4 Separate Bill Approval and Payment Release

**Profile Level:** L2 (Walk)

| Framework | Reference |
|-----------|-----------|
| CIS Controls v8 | 6 Access Control Management |
| NIST SP 800-53 Rev. 5 | AC-5 Separation of Duties |

#### Description

Use independent bill review and, on Plus, payment-release approval. Protect changes to release policy so a policy editor cannot silently remove the review they are subject to.

#### Rationale

**Why This Matters:**

- Approving a bill and authorizing its payment are distinct decisions.
- A policy without protected editing can be bypassed by changing the workflow.

**Attack Prevented:** Unauthorized payments and self-approval by a compromised finance account.

#### Prerequisites

Bill Pay policy permissions; Owner for separation of duties; Plus and at least two eligible active editors for policy-change review.

#### ClickOps Implementation

1. Open **Bill Pay settings > Approvals > Edit**. Require appropriate approvers on every relevant branch and enable Owner-controlled **Separation of Duties**.
2. Under **Payment release**, enable **Require additional approval to release payment** and route relevant payment methods through independent release steps. A branch with no steps releases automatically.
3. Enable **Require approval for policy changes**. Separate policy editors and reviewers operationally.

**Source:** [Bill Pay approvals](https://support.ramp.com/bill-pay-approvals/), [payment release and policy governance](https://support.ramp.com/bill-pay-payment-release/) (checked 2026-11-08).

**Automation:** ClickOps configuration. No matching configuration write/read endpoint was found in the [reviewed public OpenAPI catalog](https://docs.ramp.com/openapi/developer-api.json) on 2026-11-08. The [surface census](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/ramp-source-coverage.md#automation-surface-census) records the bounded API result and the distinct CLI, Alpha SDK, and unverified partner capabilities; it is not a claim of global absence.

#### Validation & Testing

1. Use workflow testing and a controlled unpaid bill; do not approve or release a real payment for validation.
2. Verify pending policy edits do not take effect until another eligible editor approves. Existing payments awaiting release retain their chains; off-Ramp payments, fully vendor-credit-paid bills, and direct-debit matches are not covered by payment-release approval.

#### Compliance Mappings

| Framework | Control | Relationship |
|-----------|---------|--------------|
| CIS Controls v8 | 6 Access Control Management | Supports the control objective; evaluate the full safeguard separately. |
| NIST SP 800-53 Rev. 5 | AC-5 Separation of Duties | Customer configuration/evidence contributes to this requirement. |

### 3.5 Require Independent Spend Review

**Profile Level:** L1 (Crawl)

| Framework | Reference |
|-----------|-----------|
| CIS Controls v8 | 6 Access Control Management |
| NIST SP 800-53 Rev. 5 | AC-5 Separation of Duties |

#### Description

Route new spend requests through explicit approval branches and enforce separation of duties. Inspect automatic-approval paths rather than assuming that adding one reviewer covers the whole workflow.

#### Rationale

**Why This Matters:**

- An approval graph can contain branches that skip review.
- Admin-created spend for another employee has different behavior from an admin's own request.

**Attack Prevented:** Self-approved spending and bypass through unreviewed request branches.

#### Prerequisites

Admin for workflow editing; Owner for separation of duties. Plus for additional entity/department/location conditions.

#### ClickOps Implementation

1. Open **Policy > Travel & expenses > Additional controls > Spend request approvals** and edit the workflow preview.
2. Add explicit approvals to each relevant branch. Choose **Require all** versus **Require any** deliberately; check annualized amount thresholds.
3. As Owner, turn on **Separation of duties** and select an independent fallback group. Check the fallback when the group has no eligible member.

**Source:** [Spend request approvals](https://support.ramp.com/setting-up-spend-request-approvals/) (checked 2026-11-08).

**Automation:** ClickOps configuration. No matching configuration write/read endpoint was found in the [reviewed public OpenAPI catalog](https://docs.ramp.com/openapi/developer-api.json) on 2026-11-08. The [surface census](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/ramp-source-coverage.md#automation-surface-census) records the bounded API result and the distinct CLI, Alpha SDK, and unverified partner capabilities; it is not a claim of global absence.

#### Validation & Testing

1. Test a new request on each branch and a requester who is also an approver.
2. Retest new requests after edits; existing approvals do not inherit the new workflow. Admin-created spend for others is auto-approved, so keep Admin membership small.

#### Compliance Mappings

| Framework | Control | Relationship |
|-----------|---------|--------------|
| CIS Controls v8 | 6 Access Control Management | Supports the control objective; evaluate the full safeguard separately. |
| NIST SP 800-53 Rev. 5 | AC-5 Separation of Duties | Customer configuration/evidence contributes to this requirement. |

### 3.6 Govern Banking Approval Changes

**Profile Level:** L3 (Run)

| Framework | Reference |
|-----------|-----------|
| CIS Controls v8 | 6 Access Control Management |
| NIST SP 800-53 Rev. 5 | AC-5 Separation of Duties |

#### Description

For businesses using Ramp Banking, separate transfer approval from automation setup and from changes to those policies. Apply review at each applicable layer.

#### Rationale

**Why This Matters:**

- Transfer controls do not themselves protect edits to their own rules.
- Automations may recur after the original setup event.

**Attack Prevented:** Unilateral changes to money-movement approval policy.

#### Prerequisites

Ramp Banking enabled; Owner for separation of duties and appropriate approval-policy permissions. This guide does not authorize a transfer or investment.

#### ClickOps Implementation

1. Open **Banking approval policies > Transfer approval policy** and require independent review for covered transfers. As Owner, enable **Separation of duties** and review fallback membership.
2. Open **Automation approval policy** and configure review for covered automation creation and changes.
3. Enable the documented **Require approval for policy changes** control for existing policies when available. Preserve at least two eligible reviewers/editors and review role permissions first.

**Source:** [Banking approvals](https://support.ramp.com/ramp-banking-approvals/) (checked 2026-11-08).

**Automation:** ClickOps configuration. No matching configuration write/read endpoint was found in the [reviewed public OpenAPI catalog](https://docs.ramp.com/openapi/developer-api.json) on 2026-11-08. The [surface census](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/ramp-source-coverage.md#automation-surface-census) records the bounded API result and the distinct CLI, Alpha SDK, and unverified partner capabilities; it is not a claim of global absence.

#### Validation & Testing

1. Use policy previews and nonfinancial test scenarios. Confirm a proposed policy edit remains pending while the existing policy stays active.
2. Document that initial policy setup and later policy edits are different cases; do not treat transaction separation of duties as protection of policy editing.

#### Compliance Mappings

| Framework | Control | Relationship |
|-----------|---------|--------------|
| CIS Controls v8 | 6 Access Control Management | Supports the control objective; evaluate the full safeguard separately. |
| NIST SP 800-53 Rev. 5 | AC-5 Separation of Duties | Customer configuration/evidence contributes to this requirement. |

## 4. Data Security

### 4.1 Restrict Financial Data by Entity

**Profile Level:** L2 (Walk)

| Framework | Reference |
|-----------|-----------|
| CIS Controls v8 | 3.3 Configure Data Access Control Lists |
| NIST SP 800-53 Rev. 5 | AC-3 Access Enforcement |

#### Description

Limit eligible finance users to the entities they manage. Review remaining aggregated information and additive roles before treating this as a confidentiality boundary.

#### Rationale

**Why This Matters:**

- Default cross-entity visibility may expose unrelated financial records.
- Admin/Owner access and aggregated data remain exceptions.

**Attack Prevented:** Unnecessary cross-entity disclosure after an account compromise.

#### Prerequisites

Ramp Plus, multiple entities, and permission to administer entity access. Eligible finance or derived Custom Roles.

#### ClickOps Implementation

1. Open **Entities settings**, select an entity, and open **Share entity access > Edit**.
2. Add required access before removing unnecessary entity access. Every restricted user must retain at least one entity.
3. Repeat for each eligible finance user and check additional roles. Admins and Owners cannot be entity-restricted.

**Source:** [Entity restrictions](https://support.ramp.com/managing-entity-restrictions-for-accounting-accounts-payable-and-finance-admin-roles/) (checked 2026-11-08).

**Automation:** ClickOps configuration. No matching configuration write/read endpoint was found in the [reviewed public OpenAPI catalog](https://docs.ramp.com/openapi/developer-api.json) on 2026-11-08. The [surface census](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/ramp-source-coverage.md#automation-surface-census) records the bounded API result and the distinct CLI, Alpha SDK, and unverified partner capabilities; it is not a claim of global absence.

#### Validation & Testing

1. Test an allowed entity and a disallowed entity with a controlled finance user.
2. Record that vendor data, card balances, and Spend Programs can remain aggregated. The API user entity_id denotes association, not the complete entity visibility grant.

#### Compliance Mappings

| Framework | Control | Relationship |
|-----------|---------|--------------|
| CIS Controls v8 | 3.3 Configure Data Access Control Lists | Supports the control objective; evaluate the full safeguard separately. |
| NIST SP 800-53 Rev. 5 | AC-3 Access Enforcement | Customer configuration/evidence contributes to this requirement. |

### 4.2 Protect Embedded Card Data

**Profile Level:** L3 (Run)

| Framework | Reference |
|-----------|-----------|
| CIS Controls v8 | 3 Data Protection |
| NIST SP 800-53 Rev. 5 | SC-8 Transmission Confidentiality and Integrity |

#### Description

For custom card integrations, prefer Ramp-hosted embedded display over retrieving full card data. Keep embedding origins narrow and avoid granting the card-vault scope to ordinary reporting apps.

#### Rationale

**Why This Matters:**

- Card-vault access exposes information that generic spend reporting does not need.
- An overly broad embed origin expands the audience that can display card details.

**Attack Prevented:** Exposure of cardholder data through compromised integration code.

#### Prerequisites

Only applicable to approved card-integration developers. Embedded/Vault access and its compliance obligations must be reviewed with Ramp.

#### ClickOps Implementation

1. Open the approved app in **Developer settings > Allowed origins**. Enter an exact approved HTTPS production origin in **Origin URL**, select **Add URL**, and follow **Verify domain ownership**. Publish the verification file with only the issued token as documented, then choose **Verify**. This does not grant an unapproved app permission to retrieve card data.
2. Confirm each origin shows **Verified**. Production excludes localhost, wildcards, redirects and non-default ports in this verification flow. Use exact localhost only in Sandbox. New integrations must load the business-specific iframe URL.
3. Use short-lived embed tokens for the intended display flow, avoid persistent client-side storage, and keep raw card data out of logs, analytics, and AI prompts. Do not enable **cards:read_vault** for routine audit packs.
4. Before minting an embed token, the application backend must authorize that the authenticated user may view that exact card_id in the intended business, and validate parent_origin. An approved origin alone does not authorize access to every card. Never send the Ramp API bearer token to the browser.

**Source:** [Virtual Cards: Embedded Cards and Vault API](https://docs.ramp.com/developer-api/v1/virtual-cards) (checked 2026-11-08).

**Automation:** Documented API integration surface exists, but this guide deliberately supplies no PAN/CVV retrieval or token-creation example. Origin approval and safe rendering require the approved application context; read-only audit packs are not a substitute.

#### Validation & Testing

1. In a sandbox, verify an approved origin works and an unapproved origin cannot display embedded details.
2. Review code and logs for card data or persisted embed tokens. The included HTH packs do not call any vault endpoint.
3. In an approved sandbox integration, test that a user cannot request another user’s unauthorized card through the backend. Perform no real card purchase or production card-data disclosure.

#### Compliance Mappings

| Framework | Control | Relationship |
|-----------|---------|--------------|
| CIS Controls v8 | 3 Data Protection | Supports the control objective; evaluate the full safeguard separately. |
| NIST SP 800-53 Rev. 5 | SC-8 Transmission Confidentiality and Integrity | Customer configuration/evidence contributes to this requirement. |

## 5. Monitoring & Detection

### 5.1 Collect and Preserve Audit Logs

**Profile Level:** L1 (Crawl)

| Framework | Reference |
|-----------|-----------|
| CIS Controls v8 | 8.2 Collect Audit Logs |
| NIST SP 800-53 Rev. 5 | AU-12 Audit Record Generation |

#### Description

Export audit events regularly into an access-controlled evidence store and reconcile collection windows. Ramp's event stream has documented coverage limitations, so combine it with IdP and integration evidence.

#### Rationale

**Why This Matters:**

- A local export preserves evidence beyond a changing console view.
- An empty result is not proof of no administrative activity.

**Attack Prevented:** Unnoticed account changes and loss of investigation evidence.

#### Prerequisites

Ramp Plus; Owner/Admin for console; existing audit_logs:read token for API. Choose an approved protected evidence destination.

#### ClickOps Implementation

1. Open **Company settings > Audit log > View audit log** and filter by actor, time range, and relevant changes.
2. Collect overlapping explicit UTC windows with the API pack. It emits only id, event_time, event_type, actor_id, and actor_type: preserve full source logs separately through an approved pipeline if forensic details are required. Deduplicate by event ID and monitor failures, lag, and unexpected empty windows.
3. Restrict export access and set retention to your organization's requirements. Treat actor identities and event details as confidential.

**Source:** [Ramp Audit Log](https://support.ramp.com/ramp-audit-log/), [Audit Logs API](https://docs.ramp.com/llms-api.txt) (checked 2026-11-08).

#### Code Implementation

{% include pack-code.html vendor="ramp" section="5.1" %}

#### Validation & Testing

1. Generate a harmless known event with a test user and compare the UI/API result. Check every page is collected and the command fails on transport, schema, or pagination errors.
2. Ramp does not log every admin action, including some integration setup. A successful export does not establish complete instrumentation or a guaranteed retention duration.

#### Compliance Mappings

| Framework | Control | Relationship |
|-----------|---------|--------------|
| CIS Controls v8 | 8.2 Collect Audit Logs | Supports the control objective; evaluate the full safeguard separately. |
| NIST SP 800-53 Rev. 5 | AU-12 Audit Record Generation | Customer configuration/evidence contributes to this requirement. |

### 5.2 Detect Security Configuration Changes

**Profile Level:** L2 (Walk)

| Framework | Reference |
|-----------|-----------|
| CIS Controls v8 | 8.11 Conduct Audit Log Reviews |
| NIST SP 800-53 Rev. 5 | AU-6 Audit Record Review, Analysis, and Reporting |

#### Description

Alert on documented identity, integration, and approval-policy event types from the audit export. Correlate with approved change records and investigate unexpected actors or timing.

#### Rationale

**Why This Matters:**

- A legitimate admin action can still be malicious.
- Policy changes may precede misuse without an immediately suspicious payment.

**Attack Prevented:** Undetected weakening of access and financial safeguards.

#### Prerequisites

Working 5.1 collection and a SIEM ingestion mapping that preserves Ramp event_type. Test events must use synthetic data.

#### ClickOps Implementation

1. Use **Company settings > Audit log** to identify actual security-change events in the tenant and establish expected change ownership.
2. In the SIEM, ingest the exported JSON records with the original **event_type** field, then translate/deploy the supplied Sigma rule for your backend. There is no universal Ramp index or native SQL table.
3. Attach relevant change tickets and route unmatched changes to a responder. Tune sanctioned changes without discarding all privileged-user events.

**Source:** [Audit Logs schema](https://docs.ramp.com/openapi/developer-api.json), [audit coverage limitations](https://support.ramp.com/ramp-audit-log/) (checked 2026-11-08).

#### Code Implementation

{% include pack-code.html vendor="ramp" section="5.2" %}

#### Validation & Testing

1. Exercise positive and negative synthetic events, then confirm a permitted real change reaches the detector.
2. Retain distinct results for rule matching, successful ingestion, and real event delivery. The rule alone proves neither full log coverage nor incident compromise.

#### Compliance Mappings

| Framework | Control | Relationship |
|-----------|---------|--------------|
| CIS Controls v8 | 8.11 Conduct Audit Log Reviews | Supports the control objective; evaluate the full safeguard separately. |
| NIST SP 800-53 Rev. 5 | AU-6 Audit Record Review, Analysis, and Reporting | Customer configuration/evidence contributes to this requirement. |

### 5.3 Maintain an Active Security Contact

**Profile Level:** L1 (Crawl)

| Framework | Reference |
|-----------|-----------|
| CIS Controls v8 | 17.1 Designate Personnel to Manage Incident Handling |
| NIST SP 800-53 Rev. 5 | IR-4 Incident Handling |

#### Description

Designate an active IT or security contact for Ramp security and login-configuration notifications, and keep the contact current through staff changes.

#### Rationale

**Why This Matters:**

- Security notices sent to an inactive contact can delay containment.
- Finance and IT need a known owner for authentication configuration and account recovery.

**Attack Prevented:** Delayed response to suspicious access and security configuration notices.

#### Prerequisites

Permission to maintain company security settings and an approved active contact. Do not substitute an unmonitored address.

#### ClickOps Implementation

1. Open **Settings > Company settings > Security**, the location linked from Ramp's Product Security guidance.
2. Review the **IT & Security Contact** setting and designate the responsible active contact using the available tenant form. Public sources do not establish exact edit/save button labels.
3. Record a backup internal escalation path and review this contact whenever administrators or the designated owner leave.

**Source:** [Trust Center IT & Security Contact / Onboarding](https://trust.ramp.com/?itemName=product_features&source=click), [fraud-awareness guidance](https://support.ramp.com/fraud-awareness-how-to-protect-your-ramp-account/) (checked 2026-11-08).

**Automation:** ClickOps configuration. No matching configuration write/read endpoint was found in the [reviewed public OpenAPI catalog](https://docs.ramp.com/openapi/developer-api.json) on 2026-11-08. The [surface census](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/ramp-source-coverage.md#automation-surface-census) records the bounded API result and the distinct CLI, Alpha SDK, and unverified partner capabilities; it is not a claim of global absence.

#### Validation & Testing

1. Confirm the saved contact is current and the person or monitored destination can receive security notices. Use an approved benign notification test if the tenant offers one; no universal test button is documented.
2. Include the contact in the identity-provider outage and session-revocation exercise, without changing live financial settings.

#### Compliance Mappings

| Framework | Control | Relationship |
|-----------|---------|--------------|
| CIS Controls v8 | 17.1 Designate Personnel to Manage Incident Handling | Supports the control objective; evaluate the full safeguard separately. |
| NIST SP 800-53 Rev. 5 | IR-4 Incident Handling | Customer configuration/evidence contributes to this requirement. |

## 6. Compliance Quick Reference

These are implementation-oriented crosswalks, not certification claims or a Ramp benchmark. Product-specific CIS, DISA STIG, and CISA SCuBA baselines were not found in the stated research boundary. The official [CIS Controls](https://www.cisecurity.org/controls/v8) and [NIST SP 800-53 Rev. 5](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final) define the underlying objectives.

| Objective | Controls | Evidence |
|-----------|----------|----------|
| Identity and account lifecycle | 1.1–1.6 | Sign-in tests, role assignments, roster reconciliation, recovery drill |
| Least-privilege integrations | 2.1–2.6 | Approved scopes, AI access, connection inventories, receiver tests, browser policy |
| Independent financial authorization | 3.1–3.6 | Restrictions, workflow branches, fallback membership, policy-change review |
| Data minimization | 4.1–4.2 | Entity-access tests, approved embed origins, absence of vault scopes |
| Audit review | 5.1–5.3 | Collection windows, completeness/error checks, ingestion and detection tests, active response contact |

## Appendix A: Feature and Plan Applicability

| Feature | Documented condition | Limitation |
|---------|----------------------|------------|
| SAML and sign-in controls | Admin/IT Admin; configured IdP | Guest password exception; SP-initiated sign-in |
| Custom roles / granular permissions | Ramp Plus | Permissions accumulate; some are implied |
| Guest role | Ramp Plus | Expiration varies by provisioning path |
| Entity restrictions | Plus and multiple entities | Admin/Owner and aggregated data exceptions |
| AI company access | All plans | Per-role control requires Plus; connection inventory may be gated |
| Audit log and API | Ramp Plus; audit_logs:read | Some admin actions absent |
| Payment release | Ramp Plus | Availability/eligible-method and existing-chain limits apply |
| Banking policies | Banking product enabled | Do not generalize to card or Bill Pay policy |
| Merchant credential collection | US businesses in current article | Distinct from browser extension receipt fetching |
| Embedded/Vault API | Approved integration | Specialized card-data and compliance obligations |

No guaranteed retention, customer-managed encryption keys, network allowlisting coverage, or government authorization is inferred from a marketing plan name.

## Appendix B: Reference and Research Boundaries

- [Security and authentication documentation](https://support.ramp.com/account-settings-and-security/security-and-authentication/)
- [Users and roles documentation](https://support.ramp.com/account-settings-and-security/users-and-roles/)
- [Developer documentation index](https://docs.ramp.com/llms.txt) and [OpenAPI specification](https://docs.ramp.com/openapi/developer-api.json)
- [Ramp CLI reference](https://docs.ramp.com/developer-api/v1/cli)
- [Trust Center](https://trust.ramp.com/) and [public Product Security configuration guidance](https://trust.ramp.com/?itemName=product_features&source=click): configuration guidance is distinct from assurance/catalog metadata
- [Source coverage](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/ramp-source-coverage.md) and [validation record](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/ramp-validation.md)
- [Code Pack README](https://github.com/grcengineering/how-to-harden/tree/main/packs/ramp)

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-11-08 | 0.1.0 | ai-drafted | Initial source-backed guide, read-only API/CLI, opt-in browser policy, and Sigma packs, source-first coverage ledger, plan limitations, and offline safety tests. No live tenant exercised. | OpenAI Codex |

## Contributing

Report corrections or propose controls through [GitHub issues](https://github.com/grcengineering/how-to-harden/issues). Include an official configuration source, applicable product/plan, and reproducible validation evidence. See the [contribution guide](/contributing/).
