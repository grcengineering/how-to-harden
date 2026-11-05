---
layout: guide
title: "OpenAI Ads Hardening Guide"
vendor: "OpenAI Ads"
slug: "openai-ads"
platform: "OpenAI"
platform_slug: "openai"
product: "Ads"
tier: "1"
category: "AI/ML Platform"
description: "Harden Ads Manager, ad-account access, OAuth and API keys, conversion measurement, partner integrations, customer audiences, feed ingestion, audit exports and signed lead delivery."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-05"
---

## Overview

This is a **product guide within the [OpenAI platform](/guides/chatgpt-enterprise/)**. Ads Manager and the Advertiser API administer **advertising accounts**. They have separate roles, keys, billing, assets and integration permissions from [API Platform projects](/guides/openai-api/) and ChatGPT workspaces. OpenAI identifies Ads Manager as a [beta product](https://help.openai.com/en/articles/20001206-ads-manager-beta-overview); enabled account features and billing arrangements determine which controls are available.

The [source-first coverage ledger](/research/openai-ads-source-coverage/) reconciles the full developer index, OpenAPI contract, account identity, browser measurement and connected services. This guide covers advertiser-controlled security boundaries. Campaign optimization, ad placement decisions and OpenAI-operated review systems are outside its hardening scope. Sponsored Agents are a [selected-advertiser alpha](https://help.openai.com/en/articles/20001524-sponsored-agents-in-chatgpt-ads), without a public advertiser configuration contract verified here; no invented agent policy is supplied.

**Validation boundary:** public first-party documentation and offline fixtures only. No live Ads account, credential, lead, campaign or configuration was used. Maturity remains AI-drafted; no product-specific CIS/STIG/SCuBA benchmark identifiers are asserted.

### Intended Audience

- Ads account administrators and marketing operations teams
- Engineers connecting measurement, CRM, merchant and reporting systems
- Security and privacy reviewers assessing account access and customer-data flows

### How to Use This Guide

Apply L1 (Crawl) identity, credential, consent, spend and evidence controls first. Use L2 (Walk) controls for automated audiences, feeds, external tools and lead delivery. A common identity-provider connection does not automatically grant access or enforce every Ads sign-in session.

### Scope

Ads Manager and Advertiser API identity, credentials, account assets, delegated spend, measurement, feeds, partners, audit and lead delivery. Campaign performance advice and OpenAI-operated review systems are outside configurable hardening scope.

## Table of Contents

1. [Identity and Credentials](#1-identity-and-credentials)
2. [Spending and Delegated Actions](#2-spending-and-delegated-actions)
3. [Measurement and Connected Data](#3-measurement-and-connected-data)
4. [Audit and Lead Delivery](#4-audit-and-lead-delivery)
5. [Compliance Quick Reference](#5-compliance-quick-reference)

## 1. Identity and Credentials

### 1.1 Review Ads Sign-In and Effective Account Access

**Profile Level:** L1 (Crawl)

#### Description

Configure Ads-specific identity and minimum account roles. A tenant identity role, Ads account-creation role and account membership are different grants. [Direct and group access combine to the highest Ads account role](https://help.openai.com/en/articles/20001273-managing-identity-and-access-for-ads-manager). Preserve an effective account administrator during offboarding.

#### Rationale

**Why This Matters:**
- A narrow direct role cannot remove higher access inherited from a group.
- A successful OpenAI sign-in does not establish which advertiser the person should administer.

**Attack Prevented:** Unauthorized account administration and residual contractor access.

#### ClickOps Implementation

1. In **Admin Console → selected tenant → Global settings → Access**, review the Ads sign-in policy. Follow the [common identity controls](/guides/chatgpt-enterprise/#11-configure-single-sign-on-sso) for the actual connection and IdP MFA/conditional access. Test with SSO Optional where available and retain an authorized recovery path.
2. Select the **advertising account → Users & groups**. Limit Admin, use Member for approved operators and Viewer for readers. Review direct and group roles. Tenant SCIM does not itself grant account access; assign synchronized groups to the specific account and review the initial Member role.
3. Change synchronized group membership in the IdP. During removal, review every direct/group path and verify the resulting access while another administrator remains.

**Session limitation:** Ads documentation says an already signed-in person may access a Required-policy account without a new SSO sign-in. Test fresh and existing sessions; do not claim Required establishes continuous IdP enforcement. Off makes SSO unavailable. [SSO setup](https://help.openai.com/en/articles/9534785-single-sign-on-sso-setup-for-openai-products)

**Automation:** Unverified — the console identity paths are documented, but no Ads-specific SSO/SCIM/account-role write contract was verified in the current public Ads OpenAPI inventory. Obtain the supported tenant contract before automating; do not substitute API Platform project endpoints. [Ads identity guide](https://help.openai.com/en/articles/20001273-managing-identity-and-access-for-ads-manager), checked 2026-11-05.

#### Validation & Testing

Test approved Viewer, Member and Admin behavior in the intended account, denial in a second account, and removal after every effective grant is withdrawn. Separately test fresh and existing sign-in sessions. Keep the reviewed access list and recovery owner.

#### Compliance Mappings

| Framework | Mapping |
|---|---|
| NIST 800-53 Rev 5 | AC-2, AC-3, AC-6, IA-2 |

### 1.2 Bind Keys and OAuth to the Intended Account

**Profile Level:** L1 (Crawl)

#### Description

Use the intended advertiser's [account-scoped Ads key](https://developers.openai.com/ads/api-reference/authentication), held server-side. Confirm the account before automation. The [current OpenAPI contract](https://developers.openai.com/ads/openapi.json) also defines Ads OAuth: request read permission for reporting, add write only for approved changes, and request refresh/identity scopes only when needed. Model API keys, conversion keys and Ads OAuth are distinct contracts.

#### Rationale

**Why This Matters:**
- A valid credential for the wrong client can expose assets or change the wrong account.
- Long-lived delegated access can survive beyond the original operator's task.

**Attack Prevented:** Cross-client changes, credential leakage and excessive partner access.

#### ClickOps Implementation

1. Select the correct advertiser in **Ads Manager → Settings → General → API Keys**. Review each integration's owner, purpose and approved secret storage. Follow the [partner setup](https://developers.openai.com/ads/api-partner-setup); keep each client's credential separate.
2. For an OAuth app, review `ads.admin.all.read` versus `ads.admin.all.write`, and whether `offline_access`, `openid` or `profile` is necessary. The spec defines the authorization-code flow and `/me` application-scoped identity. Use the approved client registration and maintained OAuth library; this pass did not verify an Ads-specific public registration, refresh-rotation or revocation contract.
3. Revoke unnecessary access through the supported live account/app controls and test the result. Review cached partner tokens, scheduled jobs and exports when offboarding; replacing a human role alone is not proof that every integration is disabled.

#### Code Implementation

{% include pack-code.html vendor="openai-ads" section="1.2" %}

This GET fails if the returned account ID differs from an independently approved value. It creates no key and proves neither OAuth consent nor effective account roles. The [audit endpoint rejects Ads OAuth access tokens](https://developers.openai.com/ads/api-reference/audit-logs); use a reviewed account key for that exporter.

#### Validation & Testing

Check account ID, currency, timezone and review state before enabling a workflow. Test an unexpected-account fixture and require failure. Keep secret values, returned key-creation responses and bearer headers out of logs. Preserve the previous approved integration until replacement access is verified, then remove it deliberately.

#### Compliance Mappings

| Framework | Mapping |
|---|---|
| NIST 800-53 Rev 5 | AC-6, IA-5, SC-12 |

## 2. Spending and Delegated Actions

### 2.1 Enforce Reviewed Spend and Activation Boundaries

**Profile Level:** L1 (Crawl)

#### Description

Use available [account spending limits](https://developers.openai.com/ads/api-reference/ad-account#account-spending-limits) as a boundary against runaway or compromised campaigns. Current daily/date-range limits require eligible postpaid invoice billing and billing-management permission, including reads. Campaign budgets remain separate. Review account, campaign, ad-group and ad activation deliberately.

#### Rationale

**Why This Matters:**
- A compromised writer can spend through several campaigns.
- Retrying a conflicted configuration blindly can defeat another administrator's change.

**Attack Prevented:** Unbounded advertising spend and accidental activation of unreviewed assets.

#### ClickOps Implementation

1. In the selected account, review available account spending controls and campaign budgets. Where the interface does not expose the required field, use the documented native API; no precise spend-settings menu is asserted by the fetched developer guide.
2. Read the current limit windows, account currency/timezone, permitted dates and configuration revision. Choose a daily or date-range limit consistent with approved interruption tolerance. Amounts are integer **micros of account currency**, distinct from API Platform USD cents.
3. For a daily edit, submit the latest `expected_revision`; refresh and reconcile after 409. After 503, read back before retrying because the write may have succeeded. New daily limits start tomorrow or later; they do not provide an immediate incident stop.
4. Use the documented account/campaign **pause** path for incident containment, then verify actual state. Do not use irreversible archive as a temporary pause. Brand-name changes can pause delivery for review; missing review data is unknown, and active account status alone does not prove readiness. [Account lifecycle](https://developers.openai.com/ads/account-management)

#### Code Implementation

{% include pack-code.html vendor="openai-ads" section="2.1" %}

The read assessment and native daily-edit payload emitter make no configuration writes. They do not enroll an ineligible account or bypass billing permissions.

#### Validation & Testing

Read back the saved configuration and retained spend counter, and check the chosen timezone and exclusive end date. Limits cover billable ad spend rather than taxes/invoices; stop propagation and delayed billing can permit overrun. Do not lower a cap or pause production merely to test it. An approved rollback must restore reviewed values with the latest revision.

#### Compliance Mappings

| Framework | Mapping |
|---|---|
| NIST 800-53 Rev 5 | AC-6, CM-3, SC-5 |

### 2.2 Review Plugin Actions and External App Authorization

**Profile Level:** L2 (Walk)

#### Description

Gate applications that can access Ads data and review proposed AI-assisted changes. For Business/Enterprise organizations, [HubSpot Ads access defaults off and requires a global admin's approval](https://help.openai.com/en/articles/20001522-setting-up-chatgpt-ads-in-hubspot); organization approval remains separate from a user's Ads authorization. The [Ads Manager plugin](https://help.openai.com/en/articles/20001558-use-the-chatgpt-ads-manager-plugin) scopes access to the connected user's accessible resources and requires confirmation for supported writes.

#### Rationale

**Why This Matters:**
- An identity-only sign-in does not authorize an external app to read advertiser data.
- Natural-language requests can select the wrong account or interpret untrusted creative content as instructions.

**Attack Prevented:** Unauthorized delegation and unintended campaign, asset or account-access changes.

#### ClickOps Implementation

1. A global admin opens **Admin Console → External access → organization owning the Ads account → application → Access**. Allow only approved Ads permissions and review connected users; disable obsolete app access. [Tenant administration](https://help.openai.com/en/articles/12289294-managing-your-tenant-in-admin-console)
2. Review each plugin change's selected account, target resource, current/proposed values, destination and budget before confirming. Recheck any revised proposal and compare the post-change read-back with the approval record.
3. Keep recurring plugin reviews recommendation-only. They do not automatically optimize campaigns. Verify billing, legal identity and account readiness in Ads Manager; the plugin cannot override those checks.

**Automation:** Unverified — documented console/plugin paths were checked 2026-11-05, but no current Ads-specific external-access policy-write schema was verified. Obtain the supported policy handle before automating; API campaign write permission is not a tenant app-approval API. [External access](https://help.openai.com/en/articles/12289294-managing-your-tenant-in-admin-console)

#### Validation & Testing

Test denied app access and an approved reader separately. Review whether plugin write proposals require the intended confirmation and reapproval when values change. Use draft/preview operations before approved changes and audit the resulting account state.

#### Compliance Mappings

| Framework | Mapping |
|---|---|
| NIST 800-53 Rev 5 | AC-3, AC-6, CM-3, SA-9 |

## 3. Measurement and Connected Data

### 3.1 Gate Browser Measurement and Minimize Signals

**Profile Level:** L1 (Crawl)

#### Description

When measurement requires consent, set the [official Pixel's consent](https://developers.openai.com/ads/measurement-pixel#control-measurement-consent) to false **before initialization**, then connect grant/withdrawal to the site's consent system. Its documented default is true unless explicitly denied or a stored denial exists. Review optional matching fields, automatic advanced matching and every Pixel recipient.

#### Rationale

**Why This Matters:**
- Initialization before consent can transmit events immediately.
- Hashing identifiers does not make unlimited collection or sharing appropriate.

**Attack Prevented:** Unapproved customer-data disclosure and unintended cross-advertiser event routing.

#### ClickOps Implementation

1. In **Ads Manager → Conversions**, confirm the intended data source/Pixel. Inventory tag-manager installations, Shopify integration and custom code; avoid duplicate recipients and production debug logging.
2. In the website's supported deployment/tag system, put `consent(false)` before `init`, then wire actual consent changes. Declining consent blocks measurement pings and removes Pixel cookies; newly granted consent permits future events without replaying previously blocked events.
3. Review optional user data and automatic advanced matching with the privacy owner. AAM detects supported information on the site and hashes it in the browser. Apply the required notices/permissions and stop server-side forwarding after withdrawal too. Image tags must render only after required consent; they do not inherit a separate JavaScript queue's protection. [Image tag](https://developers.openai.com/ads/image-tag)
4. Merge only the documented CDN/event hosts into CSP, using the site's nonce/hash mechanism. Do not add `unsafe-inline` for the Pixel. Specify the intended Pixel ID when using multiple pixels, and review all destinations. [CSP and multiple pixels](https://developers.openai.com/ads/measurement-pixel#configure-a-content-security-policy)

#### Code Implementation

{% include pack-code.html vendor="openai-ads" section="3.1" %}

#### Validation & Testing

In a disposable browser test, check the network before consent, after grant and after withdrawal. Check cookies and every configured Pixel, including duplicate tags and non-JavaScript image tags. Cookie duration is not a server-retention policy. Keep test identifiers synthetic and do not infer historical deletion from withdrawal.

#### Compliance Mappings

| Framework | Mapping |
|---|---|
| NIST 800-53 Rev 5 | AC-4, PT-2, PT-3, SC-7 |

### 3.2 Protect Server Conversion Credentials and Delivery

**Profile Level:** L1 (Crawl)

#### Description

Send [Conversions API events](https://developers.openai.com/ads/conversions-api) from the server using a Conversions key and intended Web data-source Pixel ID. Keep raw identifiers and keys out of browser bundles, URLs, logs and support messages. Use the same event ID and Pixel ID for the same browser/server conversion so retries do not inflate results.

#### Rationale

**Why This Matters:**
- A leaked conversion key permits forged event traffic.
- Repeated or mismapped events can poison optimization and disclosure records.

**Attack Prevented:** Credential theft, conversion-data poisoning and excessive customer-data transfer.

#### ClickOps Implementation

1. In **Conversions**, identify the approved Pixel and manage conversion credentials through the supported account flow. [Conversion setup](https://developers.openai.com/ads/api-reference/conversion-setup) is gated for some accounts; a 404/403 is not permission to reuse an API Platform key.
2. Define the minimum approved events and matching fields. Follow that endpoint's exact normalization/hashing rules; Pixel and custom-audience phone normalization differ. Stop forwarding revoked-consent signals, including the browser reference.
3. Validate synthetic batches with `validate_only: true` before production. Validation transmits data to OpenAI even though events are not saved; it is not an offline or zero-retention promise. One invalid event rejects the full batch, up to 1,000 events.
4. Preserve stable event IDs through retries and validate the correct data source. `integration_source` identifies the sender but does not authenticate it. Treat recent raw-event diagnostics as sensitive and limited, not a historical audit archive.

#### Code Implementation

{% include pack-code.html vendor="openai-ads" section="3.2" %}

The default emits a native validation request only. `--send` is an explicit data transfer using injected credentials; this run did not use it against OpenAI.

#### Validation & Testing

Check keys stay in the server secret manager and that generated requests force validation mode. Confirm the same synthetic conversion retains its ID across senders/retries. Test withdrawal on both paths, batch rejection and an incorrect Pixel mapping before rollout. Do not log complete request/response bodies containing customer signals.

#### Compliance Mappings

| Framework | Mapping |
|---|---|
| NIST 800-53 Rev 5 | IA-5, PT-2, SC-8, SI-10 |

### 3.3 Limit Customer Audiences and Reconcile Membership

**Profile Level:** L2 (Walk)

#### Description

Upload only approved first-party [customer audiences](https://developers.openai.com/ads/custom-audiences), minimize identifiers, and preserve the requested removal/replacement lifecycle. Broker-sourced lists are disallowed by the current guide. Hashing reduces raw identifier transfer but does not supply permission, consent or anonymity.

#### Rationale

**Why This Matters:**
- A customer list is a separate sensitive data store and access grant.
- An accepted asynchronous update can be incomplete or partially applied.

**Attack Prevented:** Unauthorized audience disclosure and stale inclusion after an intended removal.

#### ClickOps Implementation

1. Use the intended account's custom-audience workflow and an approved source list. Retain the permitted purpose, owner and removal process. Follow [Ads audience guidance](https://developers.openai.com/ads/custom-audiences), including current regional/targeting restrictions.
2. Prefer prehashed identifiers where appropriate; normalize email by trimming/lowercasing while preserving plus tags and dots. Audience phone hashes use E.164 with the leading plus; do not reuse Pixel phone hashes.
3. For Add/Remove/Replace/Merge, save the original body, idempotency key, account, audience and operation IDs. Poll the returned operation to completion. A ready audience does not prove a replacement completed, and a merge is an independent list whose future source changes do not propagate.
4. Reconcile revision conflicts and partially applied Add/Remove operations by operation ID; do not start duplicate work. Cancel only before the supported operation begins changing membership. Review dependent campaigns before archiving an audience.

#### Code Implementation

{% include pack-code.html vendor="openai-ads" section="3.3" %}

The native CSV emitter handles approved ASCII email inputs only, without uploading them. International identifiers and phone/GAID formats require their own documented normalization path.

#### Validation & Testing

Check hashes against known synthetic fixtures and avoid newline hashing. Require successful operation status and the new revision before dependent changes. Review independent merged audiences and retained source/export files during offboarding. Use privacy-safe counts rather than attempting to recover individual membership outcomes.

#### Compliance Mappings

| Framework | Mapping |
|---|---|
| NIST 800-53 Rev 5 | AC-4, PT-2, SI-12 |

### 3.4 Protect Feed Ingestion and Catalog Lifecycle

**Profile Level:** L2 (Walk)

#### Description

Restrict product/hotel feed ingestion credentials and review catalog replacement, destinations and serving eligibility. [SFTP upload access](https://developers.openai.com/ads/product-feeds) and campaign delivery are different controls. Public product/image URLs must not contain customer secrets or private catalog data.

#### Rationale

**Why This Matters:**
- A compromised feed writer can replace destinations or prices at scale.
- Pausing ingestion leaves existing ads and catalog objects in place.

**Attack Prevented:** Catalog tampering, malicious landing-page substitution and incomplete offboarding.

#### ClickOps Implementation

1. In **Ads Manager → Tools → Feeds**, review the feed, import source and upload history. [UI import options](https://help.openai.com/en/articles/20001268-create-campaigns-from-product-feeds) include file, hosted HTTPS and SFTP. Restrict source access and review destination domains, image URLs and ads/search/checkout eligibility deliberately.
2. For API SFTP workflows, select documented SSH-key authentication where practical, keep the private key outside the platform and rotate by reviewed replacement. Read back enabled/authentication state; do not export connection credentials into inventory logs.
3. Review `is_full_refresh` for eligible catalogs: full uploads can delete missing products within a day. Disabling it stops pending cleanup but does not restore deleted products. Delta updates do not constitute a full refresh. The current prose documents this field while the fetched OpenAPI settings schema omits it; verify availability before relying on it.
4. To offboard, pause the upload connection **and** the relevant delivery resources. Feed archive requires dependent campaigns/ad groups to be archived; pausing alone is insufficient. Preserve approved evidence and recovery copies before irreversible archive. Hotel inventory is limited beta with separate format/availability requirements; apply the same credential and data-boundary review. [Hotel guide](https://developers.openai.com/ads/hotel-feeds)

#### Code Implementation

{% include pack-code.html vendor="openai-ads" section="3.4" %}

#### Validation & Testing

Confirm the reader exposes no SFTP URI/password. Use synthetic catalog data to validate accepted versus processed status and intended product eligibility. Missing fields are unknown, not false. Test replacement/deletion semantics in a non-production feed; retain a reviewed restoration plan.

#### Compliance Mappings

| Framework | Mapping |
|---|---|
| NIST 800-53 Rev 5 | AC-6, CM-3, SI-7, SI-12 |

### 3.5 Review Each Connected Data Source and Disconnect Boundary

**Profile Level:** L2 (Walk)

#### Description

Treat GA4, Shopify, HubSpot and measurement partners as separate data processors and credential recipients. Verify the actual account, property/Pixel, event mappings and retained copies. Shared ownership and successful connection do not establish minimum disclosure.

#### Rationale

**Why This Matters:**
- Disconnection may stop new transfers while preserving imported data and active campaigns.
- A broad analytics source can disclose activity beyond OpenAI-attributed conversions.

**Attack Prevented:** Wrong-property disclosure, excessive event forwarding and lingering partner access.

#### ClickOps Implementation

1. **GA4 beta:** in **Conversions → Data Sources → Create → Google Analytics 4**, review organization authorization, read-only Google access and the selected property ID. Inspect mappings and last sync. Imports include property-wide aggregate activity across sources. Disconnect through the property's menu to stop new imports; previously imported reports remain. Respect Google Workspace restrictions. [GA4 guide](https://help.openai.com/en/articles/20001562-connecting-google-analytics-4-to-openai-ads-manager)
2. **Shopify:** open the ChatGPT Ads app → **Connect Account**, verify the advertiser and Pixel, and review inventory/commerce-event sharing. On disconnect, review existing campaigns/feed dependencies separately; the Ads account and campaigns are not deleted. [Shopify guide](https://help.openai.com/en/articles/20001523-set-up-chatgpt-ads-for-shopify)
3. **HubSpot:** use **Settings → Tools → Marketing → Ads → Connect account → ChatGPT Ads** after organization app approval in 2.2. Review requested permissions and lead/CRM workflows. Disconnect through **Settings → Integrations → Connected Apps → ChatGPT Ads → Actions → Uninstall**, then assess retained leads and existing campaigns separately. [HubSpot guide](https://help.openai.com/en/articles/20001522-setting-up-chatgpt-ads-in-hubspot)
4. **Measurement/mobile partners:** choose the credential type the integration requires, use the intended Web Pixel and conversion key where specified, and allow only approved event fields, postbacks and attribution sources. Review the partner's access and storage separately. Mobile partner settings and attribution windows live in that partner's platform. [Measurement partners](https://help.openai.com/en/articles/20001416-set-up-measurement-partner-integrations), [mobile partners](https://help.openai.com/en/articles/20001372-set-up-mobile-measurement-partner-integrations)

**Automation:** Unverified — the connection/disconnect console paths were checked 2026-11-05, but a universal Ads partner-connection contract and partner-specific APIs were not verified. Existing account, feed, audience and lead read packs assess only their named objects. Use the current supported partner contract before automating these connections.

#### Validation & Testing

Record the approved recipient/account/property/Pixel and event list. Test synthetic events and compare source activity with imported data. For offboarding, stop transfers, disable app permissions and credentials as appropriate, inspect campaigns and coordinate retention/deletion with each processor. Disconnect is not a deletion attestation.

#### Compliance Mappings

| Framework | Mapping |
|---|---|
| NIST 800-53 Rev 5 | AC-4, PT-2, SA-9, SI-12 |

## 4. Audit and Lead Delivery

### 4.1 Export Account Audit Records with Stable Cursors

**Profile Level:** L1 (Crawl)

#### Description

Export the selected account's [Ads audit logs](https://developers.openai.com/ads/api-reference/audit-logs) into a protected sink. Authenticate this endpoint with an Ads account key, not OAuth. Use `audit_log_type`, account audit IDs and the documented `first_id`/`last_id` cursor semantics; API Platform event schemas do not apply.

#### Rationale

**Why This Matters:**
- Console-only change history is difficult to correlate with partner activity.
- Advancing a checkpoint after a partial export loses evidence silently.

**Attack Prevented:** Undetected campaign changes and evidence gaps during an account incident.

#### ClickOps Implementation

1. Select the intended advertiser and review its supported change logs; the [Ads Manager overview](https://help.openai.com/en/articles/20001206-ads-manager-beta-overview) identifies account change-history capability. Use native API export for repeatable collection.
2. Export a reviewed time window with stable filters/order and up to 100 records per page. Follow `last_id` as `after`, rather than resource IDs; `actor_id` filters changes made by that actor.
3. Stage output, require successful completion and then advance a durable checkpoint. Overlap the next window and deduplicate on audit-log ID. Protect actor information and changed values, and map the actual schema at ingestion.

#### Code Implementation

{% include pack-code.html vendor="openai-ads" section="4.1" %}

The experimental Sigma rule uses the documented `update_campaign` example. It is a review signal rather than proof of compromise; broader event coverage must use observed/documented values.

#### Validation & Testing

Test multiple pages, repeated/missing cursors, HTTP errors and unexpected response shapes against fixtures. Require a nonzero exit on incomplete collection and verify the last page in the sink. Replay a synthetic campaign change through actual ingestion before treating the detection as operational.

#### Compliance Mappings

| Framework | Mapping |
|---|---|
| NIST 800-53 Rev 5 | AU-2, AU-6, AU-9, AU-12 |

### 4.2 Bind Signed Lead Delivery to Its Subscription

**Profile Level:** L2 (Walk)

#### Description

For available lead-sync integrations, bind each approved HTTPS receiver and signing secret to its account and subscription generation. The [current Ads OpenAPI webhook contract](https://developers.openai.com/ads/openapi.json) defines signed `lead_form.response.created` delivery, freshness headers and durable acknowledgement. A valid signature alone does not authorize arbitrary CRM routing or contact use.

#### Rationale

**Why This Matters:**
- An unsigned routing header can select the wrong customer context.
- A retried or synthetic callback can create duplicate or fictitious CRM contacts.

**Attack Prevented:** Forged leads, cross-account routing, replay and duplicate processing.

#### ClickOps Implementation

The public contract supplies API operations rather than an Ads Manager setup menu for custom lead-sync subscriptions. Use the native API and your approved receiver deployment process; no console toggle is asserted.

1. Review the destination, account and consent/retention purpose before creating a subscription. Native creation requires an idempotency key and returns a signing secret; store it directly in the approved secret manager. This pack does not create it or print it.
2. Use `OpenAI-Subscription-Id` only to select a preprovisioned candidate key, verify the **raw body** with Standard Webhooks v1 HMAC-SHA256 and timestamp checks, then require its exact match with signed `subscription_id`. Verify the signed account matches the registry.
3. Validate the full published event/response schema, minimize retained lead fields and isolate signed `synthetic` probes from production CRM processing. Atomically enqueue and deduplicate by subscription generation plus delivery ID before 2xx; retry storage failures.
4. For offboarding, inventory subscriptions, delete the approved native subscription and stop downstream forwarding. Coordinate key retirement, pending deliveries and CRM retention separately; deletion of a subscription is not historical lead deletion.

#### Code Implementation

{% include pack-code.html vendor="openai-ads" section="4.2" %}

The receiver requires a full-schema validator, registry and durable queue adapters. Its official SDK verifies the standard signature; it does not start a server. The native list has no documented cursor input in this spec, so the assessment refuses `has_more: true` instead of claiming completeness.

SDK examples use the isolated `packs/openai-ads/sdk` package and committed Bun lockfile. Install with `bun install --cwd packs/openai-ads/sdk --frozen-lockfile --ignore-scripts`; the receiver and offline fixtures use its official **openai 7.51.0** dependency.

#### Validation & Testing

Use signed synthetic fixtures to test tampering, stale timestamps, subscription mismatch, wrong account, unknown key, duplicate delivery and unavailable storage. Test production events only in the authorized environment and confirm probes never enter CRM. Do not log raw answers, signing secrets or authentication headers.

#### Compliance Mappings

| Framework | Mapping |
|---|---|
| NIST 800-53 Rev 5 | AC-4, SC-8, SI-10, SI-12 |

## 5. Compliance Quick Reference

| Area | Controls | Example NIST 800-53 Rev 5 families |
|---|---|---|
| Identity and delegated access | 1.1–1.2, 2.2 | AC, IA, SA |
| Financial and asset integrity | 2.1, 3.4 | CM, SC, SI |
| Customer-data boundaries | 3.1–3.5, 4.2 | AC, PT, SA, SI |
| Evidence and callback integrity | 4.1–4.2 | AU, SC, SI |

## Appendix A: Implementation and Source Boundaries

The official API Platform Terraform provider's full resources/data-source lists contain no Ads account resources in the fetched 1.5.0 inventory. The first-party OpenAI CLI and SDK API-administration census does not supply an Ads account CLI namespace. This guide uses verified Ads REST, the official browser Pixel/SDK verification primitives, native payload/file emitters and an experimental audit detection; it does not invent Terraform, GraphQL, MDM or SQL surfaces.

REST helpers accept only the fixed Ads or Conversions API base, put credential headers in curl stdin configuration, ignore curlrc, follow no redirects, and bound each response to 8 MiB/30 seconds with a 5-second connection timeout. Audit pages are staged in private temporary files and emitted only after full success, with a 64 MiB/10,000-page ceiling. Narrow export windows after a bound failure; keep checkpoints unchanged. Only explicit `HTH_FIXTURE_LOOPBACK=1` permits `127.0.0.1` fixture bases. Conversion validation also stages its request body privately so neither credentials nor event bodies appear in curl arguments.

Ads OAuth registration/refresh/revocation details, partner-specific APIs and Sponsored Agent configuration remain research/availability limitations, not absent capabilities. The source ledger records them. Public implementation evidence and offline mocks do not prove console paths, account entitlement, consent compliance, receiver deployment or actual enforcement.

## References

- [Ads full documentation](https://developers.openai.com/ads/llms-full.txt) and [OpenAPI](https://developers.openai.com/ads/openapi.json)
- [Ads identity and access](https://help.openai.com/en/articles/20001273-managing-identity-and-access-for-ads-manager)
- [API authentication](https://developers.openai.com/ads/api-reference/authentication) and [audit logs](https://developers.openai.com/ads/api-reference/audit-logs)
- [Measurement Pixel](https://developers.openai.com/ads/measurement-pixel), [Conversions API](https://developers.openai.com/ads/conversions-api), [custom audiences](https://developers.openai.com/ads/custom-audiences) and [feeds](https://developers.openai.com/ads/product-feeds)

## Changelog

| Date | Version | Maturity | Changes | Author |
|---|---|---|---|---|
| 2026-11-05 | 0.1.0 | ai-drafted | Initial source-first Ads guide: account identity, scoped keys/OAuth, financial/action boundaries, consent and conversion data, audiences/feeds/partners, audit and signed lead delivery. Public sources and offline tests only; no tenant exercised. | Codex (GPT-6) |
