---
layout: guide
title: "Grok Bot Hardening Guide"
vendor: "xAI (SpaceXAI)"
slug: "grok-bot"
tier: "1"
category: "AI/ML Platform"
description: "AI agent hardening for xAI Grok Bot: group-scoped access, connector and egress limits, enforced Auto-review, Team Bot governance, action recording, and hosted-computer lifecycle"
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-10-09"
---


**Product Editions Covered:** Grok Bot on Cursor Enterprise (full admin surface) and self-serve Cursor Teams (partial admin surface). Individual Cursor Pro, Pro+ and Ultra accounts, linked SuperGrok, SuperGrok Plus, SuperGrok Heavy and X Premium+ accounts, and self-serve Grok Business seats have member settings only, apart from Grok Business seat assignment (1.3). Grok Enterprise has no documented admin controls.

---

## Overview

Grok Bot inherits the Cursor team's org-wide controls, which live in the [Cursor Hardening Guide](/guides/cursor/) and are not repeated here. Those inherited controls are:

- SSO ([cursor 1.3](/guides/cursor/#13-configure-sso-with-samloidc-teams-and-enterprise))
- SCIM ([cursor 1.4](/guides/cursor/#14-enable-scim-provisioning-enterprise))
- Privacy Mode ([cursor 2.1](/guides/cursor/#21-enable-privacy-mode-for-sensitive-codebases))
- MCP allowlist mechanics ([cursor 4.1](/guides/cursor/#41-audit-and-allowlist-mcp-servers))
- Cloud Agent settings ([cursor 5.3](/guides/cursor/#53-secure-backgroundcloud-agents))
- the `*.cursorvm.com` and `*.*.cursorvm.com` proxy allowlist ([cursor 9.2](/guides/cursor/#92-configure-network-allowlisting))
- generic audit-log export ([cursor 10.1](/guides/cursor/#101-enable-cursor-usage-logging))
- spend controls ([cursor 3.3](/guides/cursor/#33-monitor-api-key-usage-and-costs))

Privacy Mode (Legacy) blocks Grok Bot entirely. The cursor 10.1 pack already pulls every audit event; control 6.2 here covers only the Grok Bot event set.

**What Grok Bot is.** In xAI's words, "Grok Bot is a computer-use agent that operates applications, browsers, and development environments. It runs in Cursor's cloud, and each user's work executes on a dedicated cloud computer. The desktop and mobile apps are thin clients for chat, review, and approvals" ([Grok Bot for teams and enterprises](https://docs.x.ai/grok-bot/teams-and-enterprises)).

- **One computer per user:** each user gets one persistent computer, a dedicated Firecracker microVM. Every Bot that user runs shares it, including its files, signed-in browser sessions and command-line credentials
- **Reach:** Bots reach company systems through connectors, which appear as plugins and use the member's accounts
- **Unattended work:** Bots keep working while the member's laptop is closed. They run unattended routines on schedules, Slack triggers and webhooks, and members can tag them on X
- **Handoffs:** Bots can hand coding work to Cursor Cloud Agents and, with permission, run commands on the member's own machine
- **Team Bots:** one Bot, along with its plugins, secrets and team memory, is shared with a whole team and with Slack

**Launch and status.**

- **2026-08-11:** xAI launched Grok Bot with the statement "Grok Bot is in beta and available today for SuperGrok, SuperGrok Plus, and SuperGrok Heavy; Cursor Pro, Pro+, and Ultra; and Cursor Teams Standard and Premium subscribers on desktop and iOS" ([Introducing Grok Bot](https://x.ai/news/introducing-grok-bot))
- **2026-08-26:** xAI wrote that Grok Bot "is now included with all SuperGrok, Cursor Pro, and Cursor Teams plans" ([Grok Bot is now included with more plans](https://x.ai/news/grok-bot-more-plans))
- **2026-09-03:** the Enterprise release "adds access, network, and audit controls" ([Grok Bot for Enterprise](https://x.ai/news/grok-bot-for-enterprise))
- **2026-09-28:** Team Bots followed: "Team Bots is available today in public beta on Teams and Enterprise plans" ([Team Bots](https://x.ai/news/team-bots))

The two August posts disagree about which plans were included at launch. Treat Cursor's [plans page](https://cursor.com/help/grok-bot/plans) as the canonical matrix, except where section 8.6 records that it disagrees with Cursor's other pages. The current documentation pages, the Admin API's Grok Bot section and the Organization API's computer operations carry no beta or GA label.

**Who administers it.** Grok Bot is an xAI (SpaceXAI) product that runs in Cursor's cloud on Cursor accounts.

- **Cursor holds the product settings:** every Grok Bot product setting lives in the Cursor dashboard, the Cursor Admin API and the Cursor Organization API. docs.x.ai mirrors the Grok Bot pages and links back to the Cursor dashboard
- **Three levers live elsewhere:** Grok Business seat assignment in console.x.ai (1.3), the IdP rules (1.2) and Google Workspace app approval (2.2). Cursor's own teams page says the same: "A few live in Team Settings, your Team Marketplace, or your identity provider" ([Cursor: Grok Bot for teams](https://cursor.com/docs/grok-bot/teams))

This guide calls the Cursor side "Cursor (the Grok Bot admin plane)". It is a standalone guide, not a product guide under a platform hub: the Cursor guide covers a different vendor (Anysphere), so this guide cross-references it instead of restructuring it. Grok chat on grok.com and the `@grok` chatbot on X are different products and out of scope.

**How this guide was produced.** This guide is **AI-drafted** from vendor documentation fetched on 2026-10-08, with corrections re-checked against the vendor pages on 2026-10-09. No Cursor dashboard, Grok Bot app or tenant was observed, and nothing here has been applied, validated or reviewed by a person.

Every console path is transcribed from documentation. xAI's and Cursor's doc trees sometimes use different labels for the same control. Where they do, the control says so, and section 8.6 lists every conflict to confirm live before rollout.

### Editions Covered

| Plan | Grok Bot access | Admin controls |
|------|-----------------|----------------|
| **Cursor Enterprise** | Cursor's plans page says to consult your account executive; the teams page says an admin enables it from the Cursor dashboard. The first enable on an eligible Enterprise team starts a trial (8.6) | Full: enable switch with Manage Group Access, Network Controls, Team Setup and Team Secrets, Allow Local Egress, Action Recording, Enforce Auto-review and Auto-review rules, group Grok Bot tabs, audit logs, OpenTelemetry Export, SCIM, Manage Bot Computers (organization admins) |
| **Cursor Teams (self-serve)** | On for every member, with no switch to turn it off | Partial: Team Rules, Cloud Agents, public template sharing, the Execution on Local Computer ceiling, connector policy through Team Marketplaces, Manage Team Bots, SSO |
| **Cursor Pro / Pro+ / Ultra** | Included | Member settings only |
| **Linked SuperGrok, SuperGrok Plus, SuperGrok Heavy, X Premium+** | Usage grant on a Cursor account | Member settings only; the link has no documented admin control |
| **Grok Business (self-serve) seat** | Through Sign in with Grok | Seat assignment in console.x.ai is the only lever (1.3) |
| **Grok Enterprise** | Through the account manager | None documented |

Grok Bot stays off for teams on Privacy Mode (Legacy) or a legacy request-based plan. Whether Teams-plan Admin API keys can call the Grok Bot write routes is contradictory in Cursor's own documentation (section 8.6). Appendix A maps every control to the plans that can apply it.

### Intended Audience
- Security engineers and GRC teams approving Grok Bot for a Cursor team
- Cursor team and organization admins rolling Grok Bot out
- Identity administrators who run the Okta or Microsoft Entra ID tenant behind Cursor SSO
- Third-party risk managers assessing hosted computer-use agents

### How to Use This Guide
- **L1 (Crawl):** Essential controls for every team that runs Grok Bot
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest options for regulated industries. In this guide they appear as options inside L2 controls, namely Team Allowlist Only in 3.1 and conversation content export in 6.1.

Each control states which plans can apply it. Many are Cursor Enterprise only, and Appendix A summarizes them.

Section 8 is an unleveled reference section. It covers risks with no admin control, documentation conflicts and member-level settings, and it adds no cheat-sheet rows.

**How the packs behave.** Every API pack verifies first and writes only with `enforce --apply`, followed by a fresh read.

- **Exit 0:** no finding in what the API can read. A pack that cannot see part of its control says so on the result line ("NOT proven: …") instead of printing "compliant", so exit 0 is not a compliant tenant on its own; the dashboard checks in each control's Validation steps still apply
- **Exit 1:** a finding, a failed action, a dry run that would change something, or a write refused after verify had already found the tenant non-compliant
- **Exit 2:** a precondition; nothing was judged
- **Runbook packs:** the 7.1 and 7.2 packs are runbook actions, not checks, and their dry runs exit 0
- **HTTP 401 and 403:** the packs treat both as "not available to this team/plan", because Cursor's docs contradict themselves on Admin API reach for Teams (8.6)

### Scope
This guide covers:

- the Grok Bot admin controls in the Cursor dashboard, the Cursor Admin API and the Cursor Organization API
- Grok Business seat assignment in console.x.ai
- the IdP sign-in rule the vendor documents for the Bot's computer browser
- Google Workspace approval of the Grok OAuth app that Grok Bot's Google plugins sign in as

Cursor-wide controls are in the Cursor guide. Okta, Entra ID, Google Workspace and Slack settings beyond the specific rules named here belong to those products' own guides. Grok chat, the `@grok` chatbot on X, the xAI API platform and the Grok Build coding agent are out of scope.

### Why Grok Bot Needs Its Own Hardening

Grok Bot meets all three conditions of the lethal trifecta described in the [ChatGPT Enterprise guide's workspace-agent section](/guides/chatgpt-enterprise/#why-workspace-agents-need-their-own-hardening-section), and it does so by default:

- **Private data** comes from the shared signed-in browser, files and connectors
- **Untrusted content** arrives through web pages, email, Slack messages, X posts and plugin results
- **External communication** runs through browser navigation, shell network calls, email and Slack sends, and allow-all egress until Network Controls are set

Bots have no identity of their own and act as the signed-in member. The vendor states "Do not use separate Bots as a security boundary" ([Approvals, security, and privacy](https://docs.x.ai/grok-bot/approvals-security-and-privacy)).

This guide's controls narrow each leg: access (section 1), connectors and reach (2), egress (3), approvals (4), sharing (5), recording (6), and lifecycle and containment (7).

---

## Table of Contents

1. [Access & Identity](#1-access--identity)
2. [Agent Reach & Connected Apps](#2-agent-reach--connected-apps)
3. [Hosted Computer & Network](#3-hosted-computer--network)
4. [Autonomy & Approvals](#4-autonomy--approvals)
5. [Sharing & Team Bots](#5-sharing--team-bots)
6. [Monitoring & Audit](#6-monitoring--audit)
7. [Lifecycle & Containment](#7-lifecycle--containment)
8. [Known Gaps and Member Guidance](#8-known-gaps-and-member-guidance)
9. [Compliance Quick Reference](#9-compliance-quick-reference)

---

## 1. Access & Identity

### 1.1 Limit Grok Bot to Approved Groups

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 6.1, 6.7 |
| NIST 800-53 | AC-2, AC-3 |
| OWASP Agentic 2026 | ASI03 |

#### Description
On Cursor Enterprise, turn Grok Bot on with **Enable Grok Bot**, then use **Manage Group Access** so only approved groups can run it, never all members by default. On self-serve Cursor Teams, gate it through team membership and assignment to the existing Cursor SSO app.

**Enterprise switch:** turning the switch off blocks every member without deleting their computers.

**Self-serve Teams:** the vendor states Grok Bot "is enabled by default, and every member has access" and "There is no switch to turn it off". The exception is a team on Privacy Mode (Legacy) or a legacy request-based plan, where it stays off. Because "Grok Bot access requires the user to be a member of your Cursor team", the Teams gate is team membership plus assignment to the existing Cursor SSO app.

#### Rationale
**Why This Matters:**
- Each enabled member gets a persistent cloud computer that all of that member's Bots share, and those Bots act with every account the member signs them into
- Self-serve Teams has no switch, so team membership and IdP assignment are the only gate there
- Terminating computers does not remove a cohort's access ("None of these remove access"), so group scoping or team removal is the documented way to remove one

**Attack Prevented:** Agent sprawl across the whole workforce before connector, network and approval controls are in place (OWASP Agentic ASI03 Identity & Privilege Abuse)

#### Prerequisites
- **Enterprise:** Cursor Enterprise plan and a team admin. Move off Privacy Mode (Legacy) first, because it "blocks Grok Bot entirely" ([cursor 2.1](/guides/cursor/#21-enable-privacy-mode-for-sensitive-codebases))
- **Teams:** the existing Cursor SSO application in your IdP ([cursor 1.3](/guides/cursor/#13-configure-sso-with-samloidc-teams-and-enterprise)). SCIM is Enterprise only ([cursor 1.4](/guides/cursor/#14-enable-scim-provisioning-enterprise))

#### ClickOps Implementation

**Step 1: Enterprise: enable Grok Bot and scope it to groups**
1. Navigate to: **Cursor dashboard** → **Grok Bot** (https://cursor.com/dashboard/bot)
2. Turn on **Enable Grok Bot**. A setup modal opens covering privacy mode, pricing and model availability
3. Select **Manage Group Access** beside the switch and limit access to the approved groups

> **Doc conflict: which groups?** The API and the Grok Bot doc's dashboard link point at two different group objects. Confirm live which list the **Manage Group Access** picker shows.
>
> - **Grok Bot doc:** links these groups to **Members > Groups** (https://cursor.com/dashboard/members?subtab=groups)
> - **Admin API:** `PUT /grok-bot/access` with mode `limited` is "for selected billing groups", with `group_…` ids from `GET /teams/groups`
> - **Billing Groups:** Enterprise only. A member can be in one at a time, and they do not accept team directory-group ids (`team_group_…`). Cursor's [Billing groups](https://cursor.com/docs/account/enterprise/billing-groups) page puts them on a different sub-tab, https://cursor.com/dashboard/members?subtab=billing-groups ("under the `Members & Groups` tab")

**Step 2: Teams: gate on team membership and SSO assignment**
1. The Grok Bot page has no enable switch on Teams. Bring members in only through **Invite Team** on the Grok Bot page or your normal Cursor invitations, and remove anyone who should not run Grok Bot from the team in the dashboard
2. **Okta:** **Admin Console** → **Applications** → **Applications** → open the existing Cursor app → **Assignments** → **Assign** → **Assign to Groups**. With SCIM (Enterprise), assign the same groups to the Cursor SCIM app and push them
3. **Entra ID:** **Microsoft Entra admin center** → **Entra ID** → **Enterprise apps** → **All applications** → open the existing Cursor enterprise app → **Users and groups** → **Add user/group** ([Microsoft Learn](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/assign-user-or-group-access-portal); the xAI doc still uses the older "Enterprise applications" label). Group-based assignment needs Entra ID P1 or P2, and nested groups are not included
4. Do not create a second Grok Bot IdP application. Teams has no SCIM. Without SCIM, unassigning a user in the IdP only blocks SSO sign-in, so the vendor says to remove the user from the team in the dashboard as well

The Okta and Entra steps are transcribed from [Configure identity and access](https://docs.x.ai/grok-bot/identity-and-access).

#### Code Implementation

The verify region reads `GET /grok-bot/access` (mode `all` or `limited`, plus the groups) and `GET /grok-bot/capabilities` (`enabled`). The enforce region lists billing groups with `GET /teams/groups`, then sends `PUT /grok-bot/access` with mode `limited` and 1 to 100 group ids.

- **Approved list:** billing groups partition the team ("Members can only be in one billing group at a time", [Admin API: billing groups](https://cursor.com/docs/account/teams/admin-api#billing-groups)), so a `limited` list that names every billing group still reaches everyone outside Unassigned. Verify therefore needs `HTH_APPROVED_GROUP_IDS` to pass a `limited` policy, and exits 2 (precondition) without it
- **Teams:** mode `all` is expected and no API call can change it. Set `HTH_PLAN=teams` and the pack reports mode `all` as not judged by API (exit 2), pointing you to the membership and IdP review
- **Writes:** a Team API key with `admin:*`. `PUT /grok-bot/access` returns 400 for an empty limited list, unknown ids, or group ids sent with mode `all`. Teams-plan reach is contradictory in Cursor's docs, and `GET /grok-bot/capabilities` is not in the every-plan read list (8.6)
- **Detection:** the Sigma rule alerts on `grok_bot_access_changed` with `new_mode` `all`, and on `sand_onboarding` (the Grok Bot enable/disable event) with `new_completed` `true`. It keys on `event_type` only, because `application_type` names the acting surface and dashboard or Admin API changes carry `cursor`, not `grok_bot`

{% include pack-code.html vendor="grok-bot" section="1.1" %}

#### Validation & Testing
1. **Enterprise:** `GET /grok-bot/access` returns mode `limited` with only the approved group ids
2. A test user outside those groups has no Grok Bot access
3. The audit log shows `grok_bot_access_changed` with `new_mode` `limited`
4. **Teams:** confirm the team member list and the IdP's Cursor app assignment hold only approved users. `GET /grok-bot/access` is expected to report mode `all` on Teams; confirm it live (8.6)

**Expected result:** Only approved groups (Enterprise) or approved team members (Teams) can open Grok Bot.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **CIS Controls v8** | 6.1 | Establish an Access Granting Process |
| **CIS Controls v8** | 6.7 | Centralize Access Control |
| **NIST 800-53** | AC-2 | Account Management |
| **NIST 800-53** | AC-3 | Access Enforcement |
| **SOC 2** | CC6.1 | Logical access security |
| **SOC 2** | CC6.2 | User registration and authorization |
| **ISO 27001:2022** | A.5.15 | Access control |
| **ISO 27001:2022** | A.5.18 | Access rights |
| **OWASP Agentic 2026** | ASI03 | Identity & Privilege Abuse |
| **Product benchmark** | — | No product benchmark exists yet |

---

### 1.2 Scope the IdP Sign-In Exception for the Bot's Computer Browser

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 6.3 |
| NIST 800-53 | IA-2, AC-17, AC-20 |
| CISA SCuBA | MS.AAD.3.1v1, MS.AAD.3.7v1 (labeled compatibility exception) |

#### Description
If Bots must open IdP-provisioned apps from their computer's browser, add a narrow, labeled sign-in exception scoped to the Cursor-assigned group and to those specific apps. In Entra, start it in report-only.

**Why an exception is needed:** the hosted computer runs Linux, is not MDM-enrolled ([Cursor: Grok Bot deployment](https://cursor.com/docs/grok-bot/deployment)), and cannot run Okta FastPass or satisfy compliant-device grants. Under device-trust policies, members therefore cannot sign in to IdP-provisioned apps from the Bot's browser.

**The vendor's fix:**

- **Okta:** a rule placed above the FastPass, managed-device and deny catch-all rules
- **Entra:** a new MFA-only policy plus exclusions on the existing blocking policies (xAI Entra steps 3 and 8), because Entra applies every matching policy rather than the highest one (see the doc-conflict callout)

**What it does not gate:** this rule never gates Grok Bot sign-in or plugin sign-in. A device-aware sign-in policy on the Cursor app itself still gates the member's own device ([okta 1.12](/guides/okta/#112-enforce-device-assurance-policies)).

#### Rationale
**Why This Matters:**
- The documented carve-out deliberately relaxes device trust and phishing-resistant MFA for the Bot's browser
- Microsoft states that the device platform comes from user agent strings and "Because user agent strings can be modified, this information isn't verified" ([Conditional Access conditions](https://learn.microsoft.com/en-us/entra/identity/conditional-access/concept-conditional-access-conditions)). It advises using device platform "with Microsoft Intune device compliance policies or as part of a block statement"
- A broad Linux or Other Desktop allow rule is therefore usable by anyone holding a phished password and a factor that is not phishing-resistant

**Attack Prevented:** Device-trust bypass by a client spoofing Linux or Other Desktop

> **Compatibility exception: SCuBA and the vendor disagree.**
>
> - **SCuBA:** CISA SCuBA MS.AAD.3.1v1 says "Phishing-resistant MFA SHALL be enforced for all users." and MS.AAD.3.7v1 says "Managed devices SHOULD be required for authentication." ([ScubaGear AAD baseline](https://raw.githubusercontent.com/cisagov/ScubaGear/main/PowerShell/ScubaGear/baselines/aad.md))
> - **Vendor:** its rule relaxes both for the Bot's browser. For Okta it says "Do not require phishing-resistant or hardware-protection factors" ([Configure identity and access](https://docs.x.ai/grok-bot/identity-and-access))
> - **This guide:** under this repository's conflict rules, the SCuBA position is the recommendation. Keep phishing-resistant MFA and managed-device requirements in force, and add this exception only if Bots must open IdP-provisioned apps
> - **Okta risk delta:** the exception is one rule. The risk delta is a password plus a non-phishing-resistant factor from any client claiming Other Desktop, limited to the named group and apps
> - **Entra risk delta:** those requirements cannot stay in force on the exception path. The exception works only if the blocking grants are lifted for exactly the group, Linux-claiming clients and the named apps (Step 2a), or, for a phishing-resistant-strength policy alone, if the optional passkey authentication strength in Step 2 satisfies it. The Entra risk delta is therefore the exclusions you record in Step 2a

> **Doc conflict: Entra policy precedence.**
>
> - **xAI:** its Entra step 3 says "Leave those policies on. Add a higher-priority policy for Grok Bot users on Linux, or exclude them from the blocking policies", and its FAQ says "laptop sign-ins keep your existing requirements" ([Configure identity and access](https://docs.x.ai/grok-bot/identity-and-access))
> - **Microsoft:** "Multiple Conditional Access policies can apply to an individual user at any time. In this case, all applicable policies must be satisfied" ([Building a Conditional Access policy](https://learn.microsoft.com/en-us/entra/identity/conditional-access/concept-conditional-access-policies))
>
> Microsoft is authoritative on how Entra evaluates policies. The new MFA policy alone therefore unblocks nothing while a compliant-device, hybrid-join, phishing-resistant-strength or approved-client/app-protection policy covers the same apps.
>
> What admits the Bot's browser is xAI's own exclusion: step 3's "or exclude them from the blocking policies" and step 8's "On existing compliant-device policies, exclude the group or exclude Linux". Taken as written, each widens beyond the stated delta:
>
> - Excluding the group drops that grant for its members on every platform and every app the policy covers, laptops included, which contradicts "laptop sign-ins are unchanged"
> - Excluding Linux drops it for every user in the policy's scope whose client claims Linux, and Microsoft says the device platform comes from user agent strings and "this information isn't verified"
>
> Step 2a below keeps the widening to the group, Linux-claiming clients and the named apps.

#### Prerequisites
- **Okta:** Identity Engine for the steps and the Terraform resource (the resource is Identity Engine only). Classic Engine has a variant, noted in Step 1
- **Entra ID:** rights to create Conditional Access policies
- The list of IdP apps Bots must open from the computer. If the answer is none, do not add the exception

#### ClickOps Implementation

**Step 1: Okta (Identity Engine)**
1. Navigate to: **Admin Console** → **Security** → **Authentication Policies** → **App sign-in**. Open the policy attached to the app; find it via **Applications** → the app → **Sign On**
2. On the **Rules** tab, select **Add rule**, and place the rule above the FastPass, managed-device and deny catch-all rules
3. **IF:** group = the Cursor-assigned group, **Device platform** = Other Desktop, **Device state** = Any
4. **THEN:** **Allowed after successful authentication**, with **Password + Another factor**
5. A rule added to a shared policy covers every app on that policy. To scope the rule to specific apps, give those apps their own policy
6. **Classic Engine:** allow Other Desktop without requiring **Device Trust** = Trusted

> **Unconfirmed label:** "Other Desktop" as an Okta label is sourced only from the xAI doc and from Terraform's `os_type` `OTHER` / `type` `DESKTOP`.
>
> - Okta's own help page ([Add an app sign-in policy rule](https://help.okta.com/oie/en-us/content/topics/identity-engine/policies/add-app-sign-on-policy-rule.htm)) does not show it
> - Okta's [Management API spec](https://github.com/okta/okta-management-openapi-spec/blob/master/dist/current/management-minimal.yaml) (2026.09.2) also lists `LINUX` in `PolicyPlatformOperatingSystemType`, which bears on xAI's "there is no Linux checkbox"
> - Confirm live whether the console now offers a Linux platform, and check in the Okta System Log during the pilot whether the Bot's browser matches Other Desktop or Linux
> - Because the vendor says not to require phishing-resistant factors in Okta, any stricter Okta factor is untested by the vendor

**Step 2: Microsoft Entra ID**
1. Navigate to: **Microsoft Entra admin center** → **Entra ID** → **Conditional Access** → **Policies** → **New policy**. The xAI doc still uses the older "Protection → Conditional Access" label; Microsoft's current path is used here ([Microsoft Learn](https://learn.microsoft.com/en-us/entra/identity/conditional-access/policy-all-users-mfa-strength))
2. **Users:** the Cursor-assigned group
3. **Target resources:** only the IdP apps the Bot must open. Never select All resources. This is an HTH value, stricter than the vendor's "Select **All resources** only if you accept that scope"
4. **Conditions** → **Device platforms:** include **Linux**, exclude **Windows** and **macOS**
5. **Grant:** **Require multifactor authentication**. For Entra only, the vendor also suggests an authentication strength that a synced passkey can satisfy, with the passkey installed on the computer by a Team Setup script (3.3, Enterprise only)
6. **Enable policy:** **Report-only**. The report-only result shows in the sign-in logs even while an existing policy still blocks the sign-in. Switch to **On** only after reviewing those logs, and before Step 2a, so the exception path is never open without its MFA grant

**Step 2a: Entra: lift the blocking grants for exactly the group, Linux and the named apps (HTH pattern)**

This split is an HTH construction from Microsoft's include and exclude rules ("The exclude action overrides the include action in a policy", [Users and groups](https://learn.microsoft.com/en-us/entra/identity/conditional-access/concept-conditional-access-users-groups)); the vendor has not tested it. Apply it to each existing policy that applies a compliant-device, hybrid-joined-device, phishing-resistant-strength or approved-client/app-protection grant to the named apps:

1. Create copy A: the same grant and the original user scope, **Target resources** = the named apps, **Users** → **Exclude** = the Cursor-assigned group, any device platform. Create it **On**; while the original policy still covers the named apps it changes nothing
2. Create copy B: the same grant, **Target resources** = the named apps, **Users** = the Cursor-assigned group, **Device platforms** = **Any device** with **Linux** excluded. Create it **On**
3. Only then, on the original policy, add the named apps under **Target resources** → **Exclude**. Microsoft warns that a policy targeting **All resources** with resource exclusions changes how low-privilege scopes are enforced ("rolling out in phases starting in March, 2026", [Target resources](https://learn.microsoft.com/en-us/entra/identity/conditional-access/concept-conditional-access-cloud-apps)), so check the impact first
4. Do not add a Linux block policy for users outside the group. Microsoft lists Linux Desktop with Microsoft Edge as a browser that supports device checks ([Conditional Access conditions](https://learn.microsoft.com/en-us/entra/identity/conditional-access/concept-conditional-access-conditions)), so a block would cut off compliant Linux users

The vendor's simpler options, excluding the group or excluding Linux on each blocking policy, also admit the Bot's browser but widen as the callout above describes. If you choose one, record it as part of this exception.

**Step 3: Keep the member-device gate**
1. Leave the device-aware sign-in policy on the Cursor app in place ([okta 1.12](/guides/okta/#112-enforce-device-assurance-policies); for Entra authentication strengths see [microsoft-entra-id 1.1](/guides/microsoft-entra-id/#11-configure-authentication-methods-and-authentication-strengths))

#### Code Implementation

Cursor and xAI expose no surface for this setting: the Admin API Grok Bot routes have no IdP-policy route. The rule is expressed through the IdP Terraform providers inside this guide's pack directory, following the precedent of `packs/slack/terraform/hth-slack-1.01-okta-saml-config.tf`.

The single Terraform file has four regions:

- **Providers:** pins okta/okta 7.0.0 and hashicorp/azuread 3.10.0. Delete the provider your root module does not use, because `var.idp` gates resources, not providers
- **Okta rule:** resolves each app's policy with the `okta_app_signon_policy` data source, which returns only the policy id and name, then creates an `okta_app_signon_policy_rule` with `groups_included`, platform `OTHER`/`DESKTOP`, access `ALLOW`, `factor_mode` `2FA` and a password knowledge constraint. `priority` has no default: the operator supplies a value, or one per policy, that places the rule above the FastPass, managed-device and deny catch-all rules, then confirms the order in the console. Identity Engine only
- **Okta read-back:** reads each rule back with the `okta_app_sign_on_policy_rule` data source, including console-made rules passed in `okta_verify_rules`. Data-source postconditions fail `terraform plan` or `apply` when a rule has no group condition, includes Okta's Everyone group or a group outside the approved list, matches a platform other than Other Desktop, requires a registered or managed device or a device assurance policy, or is not Allowed with an assurance method. A rule this file creates is read back only during apply, so that failure comes after Okta has written the rule. Two listed apps sharing one policy is a warning only (a Terraform `check` block, which never fails a run), because xAI allows a shared policy scoped by group. The data source returns no factor mode or constraints, so confirm **Password + Another factor** in the console
- **Entra policy:** creates an `azuread_conditional_access_policy` with Linux included, Windows and macOS excluded, browser clients only, named apps only and MFA, in state `enabledForReportingButNotEnforced`, which is report-only. It does not edit or split your existing blocking policies, so applying it alone unblocks nothing in Entra; do Step 2a in the console or in your own azuread code. azuread 3.10.0 has no Conditional Access data source, so Entra verification rests on `terraform plan` drift plus the Entra sign-in logs

The Okta Policies API and Microsoft Graph Conditional Access routes were not censused for this guide; they belong to the okta and microsoft-entra-id guides.

{% include pack-code.html vendor="grok-bot" section="1.2" %}

#### Validation & Testing
1. From a pilot Bot computer, sign in to one in-scope app and confirm in the Okta System Log or Entra sign-in logs that the new rule or policy matched. In Entra report-only, the policy shows as report-only success; before Step 2a the sign-in itself is expected to stay blocked by the existing policy
2. Try an out-of-scope app and confirm it is still blocked
3. **Okta:** confirm the rule targets only the Cursor-assigned group and the named apps, and that laptop sign-ins are unchanged. **Entra:** after Step 2a, confirm in the sign-in logs which policies applied, and that a group member's laptop still gets the device grant through copy B
4. `terraform plan` shows no drift

**Expected result:** In Okta, Bots can open only the named IdP apps, and every other sign-in path keeps its existing rules. In Entra, group members on a client claiming Linux reach the named apps with MFA, and all other users, platforms and apps keep their existing grants.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **CIS Controls v8** | 6.3 | Require MFA for Externally-Exposed Applications |
| **NIST 800-53** | IA-2 | Identification and Authentication (Organizational Users) |
| **NIST 800-53** | AC-17 | Remote Access |
| **NIST 800-53** | AC-20 | Use of External Systems |
| **SOC 2** | CC6.1 | Logical access security |
| **ISO 27001:2022** | A.5.17 | Authentication information |
| **ISO 27001:2022** | A.8.5 | Secure authentication |
| **CISA SCuBA** | MS.AAD.3.1v1 | Phishing-resistant MFA for all users (labeled compatibility exception) |
| **CISA SCuBA** | MS.AAD.3.7v1 | Managed devices required for authentication (labeled compatibility exception) |
| **Product benchmark** | — | No product benchmark exists yet |

---

### 1.3 Treat Grok Business Seats as Grok Bot Provisioning

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 6.1, 6.2 |
| NIST 800-53 | AC-2, AC-20 |

#### Description
A self-serve Grok Business seat can unlock Grok Bot without your Cursor team. If you run Grok Business, inventory seat holders and pending invitations, assign seats only to users whose Grok Bot use is acceptable without Cursor-team governance, and unassign on role change.

**How the path works:** a user can unlock Grok Bot without your Cursor team by choosing Sign in with Grok with a Grok account that holds a seat on a self-serve Grok Business plan. The seat's license (SuperGrok or SuperGrok Heavy) sets their usage.

**Why Cursor controls may not reach it:** the console.x.ai admin docs never mention Grok Bot, and no first-party document says Cursor-team controls apply to a user who arrives this way.

**Unassigning:** it also removes the user's team-workspace access to Grok; they keep personal workspace functionality.

#### Rationale
**Why This Matters:**
- Cursor's plan page states "If your Grok Business admin removes your seat, or changes its license, Grok Bot usage from the seat ends or changes to match" ([Plans and billing](https://cursor.com/help/grok-bot/plans)), so the seat is the only documented xAI-side lever
- No first-party page says which Cursor team, if any, such a user lands in. Cursor documents domain-verified SSO enforcement ("users on that domain are required to sign in with SSO", [SSO](https://cursor.com/docs/account/teams/sso)) and an MDM allowed-team-ID policy that logs out other team IDs ([Identity and access management](https://cursor.com/docs/enterprise/identity-and-access-management)). Neither page says how a Sign in with Grok session is treated

**Attack Prevented:** Shadow Grok Bot use by employees outside the governed Cursor team, with no network policy, no Enforce Auto-review and no audit trail

#### Prerequisites
- A self-serve Grok Business plan administered in console.x.ai
- The **Team Read-Write** permission to assign and revoke licenses (purchasing needs **Billing Read-Write**)
- Personal SuperGrok, SuperGrok Plus, SuperGrok Heavy and X Premium+ links have no documented admin control (section 8.4). Request-based Teams plans and Enterprise seats do not take a personal SuperGrok link
- Grok Enterprise does not qualify for Sign in with Grok; its Grok Bot access goes through the account manager ([SuperGrok and Grok Bot](https://cursor.com/help/grok-bot/supergrok))

#### ClickOps Implementation

**Step 1: Inventory seats and invitations**
1. Navigate to: **console.x.ai** → overview page
2. Export or record the team list with each user's license
3. Review the **Pending invitations** list. **Invite users to Grok Business** auto-provisions the selected license type on acceptance when unassigned licenses exist, so a pending invitation is a pending Grok Bot grant

**Step 2: Revoke a seat**
1. In the team list, select **...** next to the user → **Unassign License** → confirm

**Step 3: Grant a seat (approved users only)**
1. Select a user from the team list → choose an available license and assign it

Steps are transcribed from [Grok Business management](https://docs.x.ai/grok/management).

**Automation:** ClickOps only — xAI exposes no write interface for this setting ([xAI Management API reference](https://docs.x.ai/developers/rest-api-reference/management), 2026-10-08).

- **Management API:** it covers auth, billing and audit, and "license" and "seat" appear on none of those pages ([billing routes](https://docs.x.ai/developers/rest-api-reference/management/billing)). Its `GET /audit/teams/{teamId}/events` returns console team events with a free-form description, and license-assignment events are not documented ([audit routes](https://docs.x.ai/developers/rest-api-reference/management/audit))
- **SDK and CLI:** the xAI SDK, whose source tree has no license-assignment or seat-management module ([xai-sdk-python](https://github.com/xai-org/xai-sdk-python)), and the `grok` CLI, which is the Grok Build coding agent ([CLI reference](https://docs.x.ai/build/cli/reference)), have no seat commands either
- **SCIM:** xAI's SCIM role-to-license provisioning ("Associate the appropriate product license (e.g., Grok Business) with the role") belongs to console Organizations, and "Organizations are exclusive to the Enterprise tier" ([Organization](https://docs.x.ai/grok/organization), 2026-10-09). Cursor's help counts only self-serve Grok Business seats for Sign in with Grok, and says Grok Enterprise does not qualify ([SuperGrok and Grok Bot](https://cursor.com/help/grok-bot/supergrok)), so that path does not reach the self-serve seats this control covers

#### Validation & Testing
1. Each quarter, reconcile the console.x.ai team list and **Pending invitations** against the approved Grok Bot roster
2. Test with a user who has no other Grok Bot grant (no Cursor plan, no personal link), or a remaining grant will mask the result
3. Confirm that after their seat is unassigned, Sign in with Grok no longer grants Grok Bot usage. Propagation time for a seat removal is undocumented, so re-test after a delay

**Expected result:** Every Grok Business seat holder is on the approved roster, and a revoked seat ends Grok Bot usage.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **CIS Controls v8** | 6.1 | Establish an Access Granting Process |
| **CIS Controls v8** | 6.2 | Establish an Access Revoking Process |
| **NIST 800-53** | AC-2 | Account Management |
| **NIST 800-53** | AC-20 | Use of External Systems |
| **SOC 2** | CC6.2 | User registration and authorization |
| **SOC 2** | CC6.3 | Role-based access, modification and removal |
| **ISO 27001:2022** | A.5.18 | Access rights |
| **ISO 27001:2022** | A.5.23 | Information security for use of cloud services |
| **Product benchmark** | — | No product benchmark exists yet |

---

## 2. Agent Reach & Connected Apps

### 2.1 Restrict the Connectors Every Bot Inherits

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 2.5, 4.8 |
| NIST 800-53 | CM-7, AC-6, SA-9 |
| OWASP Agentic 2026 | ASI02 |

#### Description
Review the Team Marketplaces before enabling Grok Bot, and block connectors that write to systems of record, send externally or move money unless a named use case needs them. On Enterprise, also maintain the MCP allowlist.

**How inheritance works:** Grok Bot has no connector list of its own. It inherits the team's Cursor connector policy on every plan, and "Any permitted connector is available to every Bot a member runs, and a blocked one shows as **Disabled by team admin**".

**MCP allowlist:** its mechanics are in [cursor 4.1](/guides/cursor/#41-audit-and-allowlist-mcp-servers) and are not repeated here.

**Pair with Network Controls:** blocking a plugin does not block that service's website in the Bot's browser, so pair this control with Network Controls (3.1).

#### Rationale
**Why This Matters:**
- Connectors supply the private-data and external-communication legs of Simon Willison's [lethal trifecta](https://simonwillison.net/2025/Jun/16/the-lethal-trifecta/), and they do so account-wide
- OAuth tokens stay on Cursor's connector backend, but the Bot can invoke every tool they authorize
- A Team Bot plugin configured with a key is "The Bot's own credential, the same for everyone" ([Team Bots](https://docs.x.ai/grok-bot/team-bots))

**Attack Prevented:** Prompt-injected tool misuse through an over-broad connector set (OWASP Agentic ASI02 Tool Misuse)

**Real-World Incidents:**
- **[CVE-2025-54135](https://cveawg.mitre.org/api/cve/CVE-2025-54135) (CNA record published 2025-08-05):** in Cursor below 1.3.9, an indirect prompt injection could make the agent create a missing MCP settings file such as `.cursor/mcp.json` without user approval and trigger remote code execution. It was a flaw in the Cursor editor's approvals for workspace files, fixed in 1.3.9, not a Grok Bot flaw.

  Grok Bot runs on Cursor-hosted computers and inherits the team's connector policy instead ("Your team's Cursor MCP (Model Context Protocol) policy applies in full, allowing or blocking each connector", [Cursor: Grok Bot for teams](https://cursor.com/docs/grok-bot/teams)). The CVE is cited here because it shows injected content steering an agent into MCP abuse. That is why the Team Marketplace policy and, on Enterprise, the MCP allowlist ("only servers matching an allowlist entry can run", [Model and integration management](https://cursor.com/docs/enterprise/model-and-integration-management)) both need tight review.

#### ClickOps Implementation

**Step 1: Set the team's connector policy**
1. Navigate to: **Cursor dashboard** → **Plugins & MCPs** (https://cursor.com/dashboard/plugins) → **Team Marketplaces** → open the marketplace
2. Set which servers members can use. xAI documents no named per-server allow or block toggle. The levers Cursor documents on that page are **Marketplace Settings** → **Marketplace Access** (restrict a whole marketplace to Organization Groups, which needs "A Cursor Enterprise plan with an Organization"), per-plugin installation modes, and removing the plugin ([Plugins](https://cursor.com/docs/plugins))
3. Block connectors that write to systems of record, send externally or move money unless a named use case needs them

**Step 2: Enterprise: maintain the MCP allowlist**
1. Team dashboard → **MCP Configuration** (Enterprise only), following [cursor 4.1](/guides/cursor/#41-audit-and-allowlist-mcp-servers). The Grok Bot doc sends the allowlist to the same place: it points to Cursor's MCP server trust management section ([Model and integration management](https://cursor.com/docs/enterprise/model-and-integration-management))

**Step 3: Avoid the two traps**
1. The marketplace page also offers **Default On** and **Required** installation modes for Cursor surfaces. xAI says "Pushing connectors to members, whether mandatory or default-on, is not available" for Grok Bot, so do not rely on those modes here
2. Cursor warns that "Removing a linked MCP plugin from the marketplace or deleting the marketplace can delete the Team MCP server. This removes it for local users and Cloud Agents. Review the confirmation message before continuing." ([Plugins](https://cursor.com/docs/plugins))
   - **No Grok-Bot-only lever:** Grok Bot "inherits your team's Cursor connector policy", and "There is no separate Grok Bot connector list" ([Grok Bot for teams and enterprises](https://docs.x.ai/grok-bot/teams-and-enterprises)). Withholding a server from Bots therefore also withholds it from members' Cursor surfaces
   - **Enterprise:** withhold a server by leaving it off the MCP allowlist (Step 2) instead of removing its plugin: "When an allowlist is active, only servers matching an allowlist entry can run. Servers that don't match are blocked" ([Model and integration management](https://cursor.com/docs/enterprise/model-and-integration-management))
   - **Outside Enterprise:** the only per-plugin lever Cursor documents that withholds a server is removal, so read the confirmation message before removing a linked Team MCP plugin

**Step 4: If a marketplace is imported from a repository, gate the repository**
1. A marketplace created with **Import from Repo** (GitHub, GitLab, Bitbucket or Azure DevOps) is defined by `.cursor-plugin/marketplace.json` in that repository. With **Enable Auto Refresh** on (GitHub imports, with the Cursor GitHub App), "Auto Refresh re-reads the full manifest on each push, so new plugins added to the repository are picked up automatically" ([Plugins](https://cursor.com/docs/plugins#keep-plugins-up-to-date))
2. A plugin merged to the tracked branch therefore enters the team marketplace with no dashboard step, and Grok Bot inherits that marketplace as its connector policy. Require pull-request review and branch protection on that branch, or leave Auto Refresh off and select **Refresh** only after review

> **Doc conflict: labels.** The Grok Bot doc's body says "Team Marketplace" ([Grok Bot for teams and enterprises](https://docs.x.ai/grok-bot/teams-and-enterprises)) while its FAQ says "Teams Marketplace". The [Grok Bot changelog](https://x.ai/changelog/bot) entry V0.67.0 says "Marketplace is now Connect Apps", while the docs still say Marketplace. Confirm the labels live.

#### Code Implementation

**Automation:** ClickOps only — Cursor (the Grok Bot admin plane) exposes no write interface for this setting ([Admin API, Grok Bot](https://cursor.com/docs/account/teams/admin-api#grok-bot), 2026-10-09). The pack below is read-only verification. Two neighbouring surfaces were ruled out:

- **Repository-backed marketplaces:** Cursor documents one repository path, the **Import from Repo** marketplace with Auto Refresh (Step 4). It is a way to add connectors, not to restrict them, so no config pack ships. Cursor documents only that additions are picked up, not whether removing a manifest entry removes the plugin, and the manifest has no access or installation-mode field ([Plugins reference](https://cursor.com/docs/reference/plugins#marketplace-manifest-fields), 2026-10-09). Marketplace Access and the installation modes stay in **Marketplace Settings**
- **Editor allowlist:** the `~/.cursor/permissions.json` `mcpAllowlist` is documented only as "the per-user MCP auto-run allowlist" for the Cursor editor, with no Grok Bot mention

The pack is Enterprise only, because audit logs are an Enterprise feature. For the review window, it pulls from `GET /teams/audit-logs`:

- `team_marketplace`, `mcp_server_config` and `mcp_authentication` events
- `team_settings` events, keeping `setting_name` values beginning `mcp_allowlist`, because MCP allowlist edits may log there and Cursor calls that list "not an exhaustive list"

`mcp_server_config` fires for user-scope servers too (`scope` `user` or `team`). Only team-scope rows count as findings; user-scope rows, which are members configuring their own servers, print as context.

- **Detection:** a Sigma rule alerts on `team_marketplace`
- **Connector calls:** with Action Recording on (6.1), every connector call also arrives over OpenTelemetry as `cursor.grok_bot.mcp_tool_call`, without tool arguments or results

{% include pack-code.html vendor="grok-bot" section="2.1" %}

#### Validation & Testing
1. A blocked server appears in a member's Grok Bot plugins as **Disabled by team admin**
2. **Enterprise:** the read pack lists every `team_marketplace`, team-scope `mcp_server_config` and MCP-allowlist `team_settings` change since the last review, and each maps to an approved request
3. For each repository-imported marketplace, the tracked branch requires reviewed pull requests

**Expected result:** Only approved connectors are available to Bots, and every connector-policy change is accounted for.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **CIS Controls v8** | 2.5 | Allowlist Authorized Software |
| **CIS Controls v8** | 4.8 | Uninstall or Disable Unnecessary Services on Enterprise Assets and Software |
| **NIST 800-53** | CM-7 | Least Functionality |
| **NIST 800-53** | AC-6 | Least Privilege |
| **NIST 800-53** | SA-9 | External System Services |
| **SOC 2** | CC6.1 | Logical access security |
| **SOC 2** | CC9.2 | Vendor and business partner risk management |
| **ISO 27001:2022** | A.5.19 | Information security in supplier relationships |
| **ISO 27001:2022** | A.5.23 | Information security for use of cloud services |
| **OWASP Agentic 2026** | ASI02 | Tool Misuse |
| **Product benchmark** | — | No product benchmark exists yet |

---

### 2.2 Gate Google Plugins by Approving the Grok OAuth App

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 2.5, 6.1 |
| NIST 800-53 | AC-3, AC-6, CM-7 |

#### Description
In Google Workspace, keep the Grok OAuth app unapproved by default and approve it only for the organizational units that hold approved Grok Bot users. Prefer **Specific Google data**, which allows only the OAuth scopes you list, over **Trusted**.

**Why this is a second gate:** Grok Bot's Gmail, Calendar, Drive, Docs, Sheets and Slides plugins sign in to Google as the OAuth app Grok, not Cursor: "Grok Bot signs in to Google as **Grok**, not Cursor" ([Connect plugins](https://cursor.com/help/grok-bot/connect-plugins)). The Cursor connector policy (2.1) and a Google Workspace app-access decision are therefore two separate gates.

**Who is in scope:**

- **Enterprise:** `GET /grok-bot/access` names the approved groups; expand them with the groups routes or the dashboard to get the member roster
- **Self-serve Teams:** every member has Grok Bot, so the in-scope population is the whole team

**Why not Trusted:** Google says a trusted app "can request access to all Google data" and that trust "overrides a service restriction".

#### Rationale
**Why This Matters:**
- A Workspace that already reviewed Cursor has not reviewed Grok. An admin searching for Cursor misses the app that actually receives the Google grants for mailbox and Drive reach
- Plugins are account-wide: "An installed plugin is available to every bot on that Grok Bot account". A teammate's Team Bot can also use a member's accounts after an Allow prompt. The tokens stay on Cursor's connector backend, not on the computer
- Approving Grok does not undo a Cursor block: "It does not turn a Cursor marketplace plugin back on"

**Attack Prevented:** Unreviewed OAuth grants giving every Bot a member runs mail, calendar and Drive access

#### Prerequisites
- Grok stays gated only while the Workspace blocks unconfigured third-party apps (**API controls** → **Settings** → **Unconfigured third-party apps**) or restricts Gmail, Drive and Calendar. Google says "Apps that you don't trust can only access unrestricted services". Apply [google-workspace 3.1](/guides/google-workspace/#31-enable-oauth-app-whitelisting) first
- Google's app-access request feature is not available for Google Workspace for Education

#### ClickOps Implementation

**Step 1: Leave Grok unconfigured**
1. Do not add Grok under **Configured apps** → **Add app**. Google's documented Add app flow ends "Select Trusted or Blocked and click Configure", with no scope step, and "A trusted app has access to all Google Workspace services (OAuth scopes), including restricted services" ([Google: control third-party app access](https://knowledge.workspace.google.com/admin/apps/control-which-third-party-and-internal-apps-access-google-workspace-data))
2. Do not block it through **Add app** either. Google counts a blocked app as configured ("Configured apps are apps with an access policy (trusted, limited or blocked)") and documents the request queue only for "an unconfigured third-party app"
3. With unconfigured third-party apps blocked (the prerequisite), have one approved Grok Bot user in each target organizational unit connect a Google plugin. They see **Your admin needs to review Grok** and "request access if that button is there" ([Connect plugins](https://cursor.com/help/grok-bot/connect-plugins)), and Google adds Grok to **Apps pending review**

**Step 2: Approve it for Grok Bot organizational units only**
1. Navigate to: **Google Admin console** → **Menu** → **Security** → **Access and data control** → **API controls** → **App access control** → **Apps pending review** → **Grok** → **Configure access**
2. In the **Scope** section, select up to 10 organizational units (use bulk updates beyond 10) → **Next**
3. Choose **Specific Google data** and list only the Gmail, Calendar or Drive scopes the approved plugins need (see **Requestable services**), plus the Google sign-in scope: "You must include the Google sign-in scope to allow users to sign in with their managed Google Account". Leaving it out breaks every Grok plugin in a way that looks like the control working
4. Select **Next** → **Configure access** ([Google: review app access requests](https://knowledge.workspace.google.com/admin/apps/review-and-manage-third-party-app-access-requests)). Use **Trusted** only if a documented reason requires it

**Alternative when no request exists yet: bulk CSV, per organizational unit**
1. **Manage Third-Party App Access** → **Bulk update list** → **Download Blank Template**
2. Add one row per Grok Bot organizational unit: Type `web application`, Id = Grok's OAuth client ID, Access `trusted`, Org Unit = the unit's full path. Never use `/`, which applies the setting "to your entire domain"
3. **Attach CSV File** → **Upload** ([Google: add and configure third-party apps in bulk](https://knowledge.workspace.google.com/admin/apps/add-and-configure-third-party-apps-in-bulk))
4. The CSV's Access column takes only `trusted`, `blocked`, `limited` or `unconfigured`, not Specific Google data, and `limited` reaches only unrestricted services, so it will not unlock Gmail, Drive or Calendar while those services are restricted. Prefer the request path

Cursor's own help says to add the app named Grok and "Set Grok to **Trusted** for the people who use Grok Bot" ([Connect plugins](https://cursor.com/help/grok-bot/connect-plugins)). This control keeps that intent but scopes it by organizational unit, and prefers Specific Google data.

> **Gap in Google's steps:** if your console's **Add app** flow shows a Scope step, choose the Grok Bot organizational units there and never the top-level unit; Google's published Add app steps show none.

**Automation:** ClickOps only — Google Workspace exposes no write interface for per-app trust: the Cloud Identity Policy API's `api_controls` settings are "Mutate supported: No" ([Supported Policy API settings](https://docs.cloud.google.com/identity/docs/concepts/supported-policy-api-settings), 2026-10-08). Cursor and xAI expose none either ([Admin API, Grok Bot](https://cursor.com/docs/account/teams/admin-api#grok-bot), 2026-10-08).

- **Terraform:** the hashicorp/googleworkspace 0.7.0 provider has no third-party app-access resource ([registry](https://registry.terraform.io/v1/providers/hashicorp/googleworkspace))
- **Read-only:** the Policy API can read the prerequisite (`api_controls.unconfigured_third_party_apps`, `api_controls.google_services`), which google-workspace 3.1 covers

#### Validation & Testing
1. Check the prerequisite first. If the Workspace allows unconfigured apps, the test below passes vacuously
2. A member outside the trusted OU sees "Your admin needs to review Grok" or "Access blocked" when connecting a Google plugin
3. An in-scope member completes **Authorize**
4. Grok does not appear under **Configured apps** with a domain-wide (`/`) Trusted setting

**Expected result:** Only approved organizational units can connect Grok Bot's Google plugins.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **CIS Controls v8** | 2.5 | Allowlist Authorized Software |
| **CIS Controls v8** | 6.1 | Establish an Access Granting Process |
| **NIST 800-53** | AC-3 | Access Enforcement |
| **NIST 800-53** | AC-6 | Least Privilege |
| **NIST 800-53** | CM-7 | Least Functionality |
| **SOC 2** | CC6.1 | Logical access security |
| **ISO 27001:2022** | A.5.15 | Access control |
| **ISO 27001:2022** | A.5.23 | Information security for use of cloud services |
| **Product benchmark** | — | No product benchmark exists yet |

---

### 2.3 Disable Cloud Agent Delegation Unless Needed

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.8 |
| NIST 800-53 | CM-7, AC-6 |
| OWASP Agentic 2026 | ASI02 |

#### Description
Turn off the team-wide **Cloud Agents** switch, which is on by default, unless the team has a delegation use case. The switch is available on Teams and Enterprise.

**How delegation works:** Bots can delegate coding tasks to Cursor Cloud Agents, which run on separate computers under your existing Cloud Agent controls.

**Vendor guidance:** the vendor's recommended configuration says "Disable Cloud Agent spawning if you do not need delegation".

**If it stays on:** delegated work is governed by the Cloud Agent settings in [cursor 5.3](/guides/cursor/#53-secure-backgroundcloud-agents), not by this guide's network policy ("The policy is separate from Cloud Agent network settings").

#### Rationale
**Why This Matters:**
- Delegation extends each Bot's reach to a second compute surface with its own network and credential settings
- Auto Review judges each Cloud Agent launch, and can deny one, but does not disable the capability; only the team switch does
- On Enterprise, a group's Grok Bot tab can re-allow Cloud Agents for a cohort (4.3)

**Attack Prevented:** A hijacked Bot fanning work out beyond the Grok Bot network policy (OWASP Agentic ASI02 Tool Misuse)

#### ClickOps Implementation

**Step 1: Turn delegation off for the team**
1. Navigate to: **Cursor dashboard** → **Grok Bot** page (https://cursor.com/dashboard/bot)
2. Under the agent capabilities, set **Cloud Agents** to off. The switch is set by admins on Teams and Enterprise

**Step 2: Enterprise: check group overrides**
1. **Members > Groups** → [group] → **Grok Bot** tab → **Agent Capabilities** → confirm the group does not allow Cloud Agents (see 4.3). The docs describe this only in prose ("Allow Cloud Agents"), so transcribe the exact toggle label live (8.6)

#### Code Implementation

- **Verify:** the pack's verify region reads `cloudAgents` from `GET /grok-bot/capabilities` and fails unless it is `false`
- **Enforce:** the enforce region sends `PATCH /grok-bot/capabilities` with `{"cloudAgents": false}`. Omitted fields stay unchanged, the call needs `admin:*`, and it "Returns **403** when a field is not available to the team"
- **Plan reach:** writes are confirmed for Enterprise; Teams-plan reach is unconfirmed (8.6)
- **Group overrides:** the read returns the team baseline only; no route returns a group tab's override
- **Evidence of use:** with Action Recording on, `cursor.grok_bot.delegation` events (`delegation.kind` `cloud_agent_launch` or `cloud_agent_followup`) record handoffs. A launch Cursor rejected is not recorded

{% include pack-code.html vendor="grok-bot" section="2.3" %}

#### Validation & Testing
1. `GET /grok-bot/capabilities` returns `"cloudAgents": false`
2. **Enterprise:** confirm in the dashboard that no group's Grok Bot tab re-allows Cloud Agents, and that no `grok_bot_group_settings` audit event shows one doing so (4.3)

**Expected result:** No Bot can launch a Cloud Agent, except for a recorded, approved group exception.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **CIS Controls v8** | 4.8 | Uninstall or Disable Unnecessary Services on Enterprise Assets and Software |
| **NIST 800-53** | CM-7 | Least Functionality |
| **NIST 800-53** | AC-6 | Least Privilege |
| **SOC 2** | CC6.1 | Logical access security |
| **ISO 27001:2022** | A.8.9 | Configuration management |
| **OWASP Agentic 2026** | ASI02 | Tool Misuse |
| **Product benchmark** | — | No product benchmark exists yet |

---

### 2.4 Set the Team Execution on Local Computer Ceiling to Never Allow

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1, 4.8 |
| NIST 800-53 | AC-6, CM-7, AC-17 |
| OWASP Agentic 2026 | ASI02, ASI05 |

#### Description
Set the team **Execution on Local Computer** ceiling to **Never allow** unless Bots have a specific reason to work on member machines. The control is available on Teams and Enterprise.

**What local execution allows:** through the desktop app, Bots can "run commands, read files, and move files between the cloud computer and the local machine" ([Grok Bot security](https://docs.x.ai/grok-bot/security)).

**Defaults:** the team default, **Always allow**, "leaves the choice to each member", and the member's own setting defaults to asking before every task. "A member's own setting still applies when it is stricter than the team's."

**Group overrides (Enterprise):** recheck group Grok Bot tabs (4.3), which can raise the ceiling for a cohort ("Group settings only widen").

#### Rationale
**Why This Matters:**
- Local execution carries untrusted cloud-side input onto a managed endpoint that holds corporate credentials and network reach
- The [Grok Bot changelog](https://x.ai/changelog/bot) V0.37.0 (September 3, 2026) Fixed list includes "Allow once works even when Execution on this computer is set to Never allow". That is the member's own per-computer setting, so at member level a one-time approval still runs
- The team ceiling is the setting to rely on, and its interaction with **Allow once** must be validated live

**Attack Prevented:** Prompt-injected commands executing on employee laptops (OWASP Agentic ASI02 Tool Misuse, ASI05 Unexpected Code Execution)

#### ClickOps Implementation

**Step 1: Set the team ceiling**
1. Navigate to: **Cursor dashboard** → **Grok Bot** page (https://cursor.com/dashboard/bot) → **Execution on Local Computer**
2. Select **Never allow**. The documented options, in order, are **Always allow**, **Ask every time** and **Never allow**

**Step 2: Enterprise: check group overrides**
1. **Members > Groups** → [group] → **Grok Bot** tab → **Agent Capabilities**: confirm no group raises the Execution on Local Computer ceiling (see 4.3)

> **Doc conflict: member path.** The two vendor domains document the member setting at different paths. Confirm the path live.
>
> - **xAI:** its [Approvals, security, and privacy](https://docs.x.ai/grok-bot/approvals-security-and-privacy#control-access-to-your-local-computer) page puts the member setting under **Settings → General → Bot → Execution on Local Computer**. It then says that once computers are registered, "the choice moves to **Settings → Computer → Computers**, where each computer has its own **Execution on this computer** setting"
> - **Cursor:** its [Grok Bot security](https://cursor.com/docs/grok-bot/security) doc writes **Settings > Computer > Execution on this computer**, with no Computers level
> - **Per desktop:** the setting is per desktop ("**Execution on Local Computer** is set per computer", [Settings and notifications](https://docs.x.ai/grok-bot/settings-and-notifications)), so the team ceiling is the only control that covers every member machine
> - **Lock state:** xAI says "If your team's admin has set a stricter ceiling, **Always allow** is unavailable", but it says so in its description of the first-run approval prompt. No doc describes a locked state or lock message in Settings

#### Code Implementation

- **Verify:** the verify region reads `localExecution` from `GET /grok-bot/capabilities` (`never`, `ask`, `always` or `null`). It asserts exactly `never`, because `null` means no ceiling
- **Enforce:** the enforce region sends `PATCH /grok-bot/capabilities` with `{"localExecution": "never"}`; `null` clears the ceiling. Writes are confirmed for Enterprise; Teams-plan writes are unconfirmed (8.6)
- **Detection:** two Sigma rules cover the Enterprise OpenTelemetry stream from Action Recording. One fires on `cursor.grok_bot.shell_command` with `cursor.grok_bot.shell.target` = `user_machine`. The other fires on `cursor.grok_bot.file_transfer` with `cursor.grok_bot.file.target` = `user_machine`, where `file.direction` is `read`, `upload` or `download`
- **Audit:** the audit log also records a local computer being registered or renamed (`grok_bot_machine`) and a group raising the ceiling (`grok_bot_group_settings`)

{% include pack-code.html vendor="grok-bot" section="2.4" %}

#### Validation & Testing
1. `GET /grok-bot/capabilities` returns `"localExecution": "never"`
2. On a member desktop registered under **Settings → Computer**, confirm that **Always allow** is unavailable under the team ceiling. Record whether **Ask every time** stays selectable and what lock text appears, if any; no doc describes either
3. Test **Allow once** against the team ceiling (changelog V0.37.0)
4. **Enterprise with Action Recording:** confirm zero `shell_command` records with `cursor.grok_bot.shell.allowed` `true` and zero `file_transfer` records with `cursor.grok_bot.file.outcome` `success`, both with target `user_machine`. Blocked or denied attempts are expected, because these records also cover commands a Bot "was blocked from running" ([Wire Reference](https://cursor.com/docs/enterprise/opentelemetry-export/wire))

**Expected result:** No Bot reads, writes or runs anything on a member's machine.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **CIS Controls v8** | 4.1 | Establish and Maintain a Secure Configuration Process |
| **CIS Controls v8** | 4.8 | Uninstall or Disable Unnecessary Services on Enterprise Assets and Software |
| **NIST 800-53** | AC-6 | Least Privilege |
| **NIST 800-53** | CM-7 | Least Functionality |
| **NIST 800-53** | AC-17 | Remote Access |
| **SOC 2** | CC6.1 | Logical access security |
| **SOC 2** | CC6.8 | Prevention and detection of unauthorized software |
| **ISO 27001:2022** | A.8.1 | User endpoint devices |
| **ISO 27001:2022** | A.8.9 | Configuration management |
| **OWASP Agentic 2026** | ASI02 | Tool Misuse |
| **OWASP Agentic 2026** | ASI05 | Unexpected Code Execution |
| **Product benchmark** | — | No product benchmark exists yet |

---

## 3. Hosted Computer & Network

### 3.1 Enforce a Destination Allowlist with Network Controls

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 9.3, 13.4 |
| NIST 800-53 | SC-7, SC-7(5), AC-4 |
| OWASP Agentic 2026 | ASI01 |

#### Description
On Enterprise, set Grok Bot Network Access to **Defaults + Team Allowlist**, or to **Team Allowlist Only** for regulated work (L3), and turn on **Lock for All Groups**. Without a policy, Bot egress is allow-all.

**Modes:**

- **Defaults + Team Allowlist** permits Cursor's default destinations plus your list
- **Team Allowlist Only** permits only your list plus the destinations a computer needs to function

**Plans and defaults:** "Teams without a policy default to allow-all", and "Self-serve Teams do not see this panel and cannot set a destination allowlist" ([Grok Bot security](https://docs.x.ai/grok-bot/security)).

**Why lock it:** without **Lock for All Groups**, a group's own policy "replaces the team's for their members".

**Applying changes:** running computers apply changes within about a minute, and sleeping ones apply them when they next wake; no recreate is needed.

**Related settings:**

- The policy is separate from Cloud Agent network settings and from connector policy (2.1)
- Allow Local Egress (3.2) is a different concern. The vendor's private-networks page covers both desktop routing and Team Setup, and it says the network policy "is a separate layer that still applies; private network reach does not replace your destination allowlist" ([Connect to private networks](https://docs.x.ai/grok-bot/private-networks))
- Desktop routing still changes the Bot's source identity and reach: "Destinations see your desktop's IP address, and the Bot can reach networks available from that device" ([Settings and notifications](https://docs.x.ai/grok-bot/settings-and-notifications)). Turn it off as well (3.2)

#### Rationale
**Why This Matters:**
- This is the product's destination-egress control. Cursor's security page says "the product control is the destination allowlist rather than a source IP editor" ([Cursor: Grok Bot security](https://cursor.com/docs/grok-bot/security)), and "Dedicated data loss prevention hooks are not available."
- By default Bot traffic leaves from shared static egress IPs: "The ranges are shared across Grok Bot customers, and dedicated per-customer IPs are not available." Source-IP trust cannot distinguish your Bots from other customers' Bots
- The vendor lists the network policy among the controls that do not depend on a model's judgment, unlike Auto Review (4.1)

**Attack Prevented:** Exfiltration to arbitrary hosts via URL parameters, shell network calls or downloads after prompt injection (OWASP Agentic ASI01 Agent Goal Hijack)

**Real-World Incidents:**
- **Adversa AI, "Cryptographic Context Injection" (2026-08-20):** an encrypted payload on an ordinary-looking web page made xAI Grok web chat (its agentic browsing framework) decrypt it and open a URL carrying the user's prompts. The attack was still reproducible as of August 19. It was demonstrated on Grok chat, not Grok Bot; an egress allowlist blocks the exfiltration host either way ([Adversa AI](https://adversa.ai/blog/cryptographic-context-injection-grok-data-theft/))
- **Radware ShadowLeak (2025-09-18, Zvika Babo and Gabi Nakibly):** zero-click indirect prompt injection made ChatGPT Deep Research leak inbox data "directly from OpenAI's cloud infrastructure, making it invisible to local or enterprise defenses". Grok Bot computers occupy the same service-side egress position ([Radware](https://www.radware.com/blog/threat-intelligence/shadowleak/); the host serves a bot wall to automated fetchers and was read in a real browser on 2026-10-08)

#### Prerequisites
- Cursor Enterprise. The panel does not exist on self-serve Teams
- A reviewed destination list (domains, wildcard domains, IP addresses, CIDR ranges, and `host-or-CIDR:port` entries for raw connections)

#### ClickOps Implementation

**Step 1: Set the team policy**
1. Navigate to: **Cursor dashboard** → **Grok Bot** page (https://cursor.com/dashboard/bot) → section **Network** → control **Grok Bot Network Access**
2. Choose **Defaults + Team Allowlist** (L2) or **Team Allowlist Only** (L3). The other modes are **No Policy (Allow All)** and **Allow All Network Access**
3. Add destinations: domains and IP ranges, with ports for raw connections
4. Turn on **Lock for All Groups**, so that a group's **Group Network Access** cannot replace the team policy

**Step 2: Turn off desktop routing**
1. Turn off Allow Local Egress (3.2)

The section and control labels (**Network**, **Grok Bot Network Access**, **Lock for All Groups**, **Group Network Access**) appear only on [Grok Bot for teams and enterprises](https://docs.x.ai/grok-bot/teams-and-enterprises#network-controls). The four mode labels also appear on docs.x.ai's [Grok Bot security](https://docs.x.ai/grok-bot/security) page. The cursor.com copies, and docs.x.ai's private-networks page, write the modes in sentence case ("Defaults plus team allowlist", "Team allowlist only").

> **Doc conflict: allowlist size.** The security page says there is "no cap on the number of entries". The Admin API's `PUT /grok-bot/network` accepts "Up to 500 destinations, 1 to 253 characters each". The pack enforces the API limit.

#### Code Implementation

- **Read:** `GET /grok-bot/network` returns `egressMode` (`unset`, `allow_all`, `default_with_network_settings` or `network_settings_only`), `allowlist` and `locked`. It is documented as readable on every plan, so a Teams admin can prove the policy is unset, which means allow-all
- **Write:** `PUT /grok-bot/network` is a full replace. All three fields are required, partial bodies, unknown modes and invalid entries return 400, and it "Returns **403** on Teams plans"

What the pack does:

- **Verify** reads the policy on any plan. It flags a mode that restricts nothing, `locked` `false`, and catch-all entries (`0.0.0.0/0`, `::/0` or a bare `*`, with or without a port) that make a restrictive mode allow-all in practice
- **Enforce** PUTs a reviewed allowlist file with `locked` set to `true` and the `egressMode` named by `HTH_EGRESS_MODE`: `default_with_network_settings` ("Cursor defaults plus the allowlist") for L2 or `network_settings_only` ("The allowlist and destinations required to run Grok Bot") for L3 ([Admin API: replace network policy](https://cursor.com/docs/account/teams/admin-api#replace-grok-bot-network-policy)). It rejects files of more than 500 entries
- **Mode choice:** because the PUT is a full replace, enforce never picks L3 on its own. Without `HTH_EGRESS_MODE` it keeps a live restrictive mode and otherwise sends `default_with_network_settings`
- **Audit:** no Grok-Bot-specific event names the team network policy. `team_settings` fires for team-wide changes "including changes made through the Admin API" and may carry it, but its `setting_name` values are not enumerated, so this is unverified. No event records an allowlist block. `grok_bot_group_settings` plausibly records Group Network Access changes, with the same caveat
- **Evidence of use:** with Action Recording and OpenTelemetry Export on, `cursor.grok_bot.browser_navigation` (`cursor.grok_bot.browser.url`, normalized to `scheme://host/path`) gives after-the-fact destination evidence for browser navigation only

{% include pack-code.html vendor="grok-bot" section="3.1" %}

#### Validation & Testing
1. `GET /grok-bot/network` returns `egressMode` `network_settings_only` (or `default_with_network_settings`) with `"locked": true`
2. Ask a pilot Bot to fetch a host that is not on the allowlist and confirm it fails

**Expected result:** Bot computers reach only allowlisted destinations, and no group can replace the team policy.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **CIS Controls v8** | 9.3 | Maintain and Update Network-Based URL Filters |
| **CIS Controls v8** | 13.4 | Perform Traffic Filtering Between Network Segments |
| **NIST 800-53** | SC-7 | Boundary Protection |
| **NIST 800-53** | SC-7(5) | Deny by Default — Allow by Exception |
| **NIST 800-53** | AC-4 | Information Flow Enforcement |
| **SOC 2** | CC6.6 | Logical access security against threats from outside system boundaries |
| **ISO 27001:2022** | A.8.20 | Networks security |
| **ISO 27001:2022** | A.8.22 | Segregation of networks |
| **OWASP Agentic 2026** | ASI01 | Agent Goal Hijack |
| **Product benchmark** | — | No product benchmark exists yet |

---

### 3.2 Turn Off Allow Local Egress

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 12.2, 13.4 |
| NIST 800-53 | SC-7, AC-4, AC-17 |

#### Description
Turn off **Allow Local Egress** for the team, and confirm that no group's Grok Bot tab turns it back on. Enterprise only.

**What it does:** Allow Local Egress lets members route the cloud computer's web traffic through their own desktop. Destinations then see the desktop's IP address, and the Bot can reach networks available from that device.

**Turning it off:** "Turning it off stops active routes within five minutes", and turning it back on restores each member's previous choice.

**Group check:** a group's Grok Bot tab can still "turn on Allow Local Egress for group members when the team has them off", and a member in several groups gets the most permissive result, so the group check is part of this control.

**Private-network access:** if a cohort needs it, prefer a Team Setup networking client with a scoped key (3.3) over routing through laptops.

#### Rationale
**Why This Matters:**
- Routing through a corporate laptop gives the Bot the laptop's source IP and every network that device reaches
- IP-based trust and internal reach therefore extend to an agent driven by untrusted input
- The vendor notes Network Controls "is a separate layer that still applies; private network reach does not replace your destination allowlist" ([Connect to private networks](https://docs.x.ai/grok-bot/private-networks)), so this control is about reach and source identity, not about bypassing 3.1

**Attack Prevented:** Lateral movement from a hijacked Bot into internal networks reachable from member devices

#### ClickOps Implementation

**Step 1: Turn the team switch off**
1. Navigate to: **Cursor dashboard** → **Grok Bot** page (https://cursor.com/dashboard/bot) → **Allow Local Egress** → Off (it is on by default)

**Step 2: Check every group**
1. **Members > Groups** (https://cursor.com/dashboard/members?subtab=groups) → each team-owned group → **Grok Bot** tab → **Agent Capabilities**
2. Confirm **Allow Local Egress** is not turned on for the group

> **Doc conflict: member labels.** The two vendor domains label the member-side toggle and its locked message differently.
>
> - **Toggle:** the member-side toggle this locks is in the Grok Bot desktop app under **Settings → Computer → Network → Route traffic through this computer**. docs.x.ai's settings page labels it "Route egress through this desktop" instead
> - **Locked message:** "Disabled by your admin. You can't turn this on." on cursor.com ([Cursor: Grok Bot settings](https://cursor.com/docs/grok-bot/settings)), and "Your team's admin has turned off local egress." on docs.x.ai ([Settings and notifications](https://docs.x.ai/grok-bot/settings-and-notifications))

#### Code Implementation

- **Verify:** the verify region reads `localEgressAllowed` from `GET /grok-bot/capabilities`
- **Enforce:** the enforce region sends `PATCH /grok-bot/capabilities` with `{"localEgressAllowed": false}`. The Admin API calls this "Allow Local Egress Routing" and marks it Enterprise only. It needs `admin:*`, an empty PATCH returns 400, and the field "Returns **403** when local egress routing controls are not enabled for the team"
- **Group overrides:** the read returns the team baseline only, so a group re-enabling local egress is invisible to it. The 4.3 pack flags group-setting changes inside its audit window; only the dashboard review in Step 2 sees overrides set earlier
- **Audit:** no audit event names the team toggle. `grok_bot_group_settings` records a group re-enabling it, and `team_settings` may carry the team toggle, but this is unverified because its `setting_name` list is non-exhaustive

{% include pack-code.html vendor="grok-bot" section="3.2" %}

#### Validation & Testing
1. `GET /grok-bot/capabilities` returns `"localEgressAllowed": false`
2. Every group's Grok Bot tab leaves **Allow Local Egress** off
3. On a member desktop, the toggle shows as locked with one of the two documented messages

**Expected result:** No member can route Bot traffic through their own device.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **CIS Controls v8** | 12.2 | Establish and Maintain a Secure Network Architecture |
| **CIS Controls v8** | 13.4 | Perform Traffic Filtering Between Network Segments |
| **NIST 800-53** | SC-7 | Boundary Protection |
| **NIST 800-53** | AC-4 | Information Flow Enforcement |
| **NIST 800-53** | AC-17 | Remote Access |
| **SOC 2** | CC6.6 | Logical access security against threats from outside system boundaries |
| **ISO 27001:2022** | A.8.20 | Networks security |
| **ISO 27001:2022** | A.8.22 | Segregation of networks |
| **Product benchmark** | — | No product benchmark exists yet |

---

### 3.3 Govern Team Setup Scripts and Keep Credentials in Team Secrets

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 2.7, 4.1, 10.1 |
| NIST 800-53 | CM-3, CM-5, SI-4, IA-5(7) |

#### Description
Treat Team Setup manifests and Group Setup Scripts as fleet-wide privileged code: put two-person change control around them, keep credentials in Team Secrets rather than in scripts, and scope any shared networking-client auth key to the minimum hosts. Enterprise only.

**How Team Setup runs:**

- Manifests run as the computer user, with sudo available, on every team computer
- They run at start and on a roughly daily refresh, with a 30-minute timeout per script, and entries run in order
- They are the Enterprise path to install your own EDR, networking clients (Tailscale, Cloudflare Tunnel) and password managers, because Grok Bot "does not ship a built-in customer-facing telemetry or EDR feed" ([Grok Bot security](https://docs.x.ai/grok-bot/security))
- Group Setup Scripts run alongside Team Setup and read the same Team Secrets; there are no group-level secrets

**Change control:** the vendor documents no approval workflow on manifest saves, so two-person change control is an HTH process recommendation.

**Secrets:** never paste secret values into scripts; store credentials as [Team Secrets](https://docs.x.ai/grok-bot/teams-and-enterprises#team-secrets).

**Shared auth keys:** every computer joins under the same key and tags, which is why the key must be scoped to the minimum hosts.

#### Rationale
**Why This Matters:**
- One manifest change executes on every member's computer. Manifests are "plain text applied to your whole fleet", and members can review the managed setup under **Team Setup** in the app ([Connect to private networks](https://docs.x.ai/grok-bot/private-networks))
- Team Secrets are encrypted and never shown again. They exist only in Setup and Check Script processes, they are redacted from output, and they are not delivered when a computer takes setup from two or more teams
- Team admins, including unpaid admins, can add, replace or delete Team Secrets, and no audit event is documented for those changes

**Attack Prevented:** A malicious or credential-leaking setup script rolled out to the whole fleet, and standing secrets kept in plain text

**Real-World Incidents:**
- **xAI developer API key leaked on GitHub (KrebsOnSecurity, 2025-05-01):** GitGuardian found that the key had access to "at least 60 fine-tuned and private LLMs", including several unreleased Grok models. GitGuardian alerted the employee on March 2, and the key was still valid on April 30. This is the plain-text-secret failure mode that Team Secrets exists to avoid ([KrebsOnSecurity](https://krebsonsecurity.com/2025/05/xai-dev-leaks-api-key-for-private-spacex-tesla-llms/))

#### Prerequisites
- Cursor Enterprise
- A change-control process (two-person review) for manifest and Setup Script edits
- Limits: up to 100 manifests per team; up to 100 secrets per team, 32 KB per value and 96 KB in total

#### ClickOps Implementation

**Step 1: Author or review a team manifest**
1. Navigate to: **Cursor dashboard** → **Grok Bot** → **Team Setup** → **Manifests** → **+** (New Manifest) → **Manifest ID**
2. Add each script entry (ID, **Setup Script**, optional **Check Script**); a **Form**/**JSON** toggle sits at the top of the editor → **Save**
3. Cohort-only scripts live under **Members > Groups** → [group] → **Grok Bot** tab → **Setup Scripts**. Review them on the same schedule

**Step 2: Move credentials into Team Secrets**
1. **Cursor dashboard** → **Grok Bot** → **Team Secrets** → add the environment variable name and value
2. Reference the secret by name from the script's environment, and remove any literal value from manifest text

**Step 3: Roll out**
1. **Organization admins (Enterprise):** **Grok Bot** → **Bot Computers** → **Manage Bot Computers** → **Manage** → select members → **Manage selected** → **Recreate VMs** → confirm **Recreate VMs**
2. Otherwise a member reset or the roughly daily refresh picks up changes
3. If the Grok Bot page shows the banner "Restart VMs to apply changed settings", team admins can select **Restart all VMs** → **Recreate VMs**. The banner is documented only as appearing "after some changes to team settings"
4. A recreate removes apps members installed themselves, and sign-in sessions, including the networking client's login, may need re-establishing

#### Code Implementation

- **Read:** `GET /grok-bot/setup-manifests` lists team manifests (`id`, and `scripts` with `id`, `setup` and `check`), paged at 50 by default and 100 at most
- **Write:** `PUT /grok-bot/setup-manifests/:manifestId` upserts one, and `DELETE` removes it. A PUT returns 409 when the manifest changed during the request, and 403 when the feature is not available to the team or its plan

What the pack does:

- **Verify** lists team manifests and flags credential-shaped literals in setup and check text:
  - AWS key ids, PEM private keys, GitHub and Slack tokens
  - Tailscale `tskey-` auth keys and Cloudflare Access `cfast_` client secrets
  - credentials in URLs, `key=value` assignments and literal Authorization headers
  - secret flags passed as a separate argument, such as `tailscale up --auth-key tskey-…` or `cloudflared access tcp --service-token-secret <value>`
- **Verify results:** a reference to an environment variable (`--auth-key "$TS_AUTHKEY"`) passes. Matches are reported by pattern name only, and a clean scan is not proof of absence
- **Enforce** upserts a reviewed manifest file only when it is missing or differs from the live copy, and refuses a file that itself carries a credential-shaped literal. Its dry run prints each script's id and length, never the script text, so a literal the scan missed never lands in a CI log
- **Detection:** a Sigma rule alerts on `grok_bot_team_setup_manifest` (save or delete, with revision, entry count and entry ids) and on `grok_bot_group_resource` with resource `setup_manifest`. Script text is never logged. Recreates are audited as `grok_bot_vm` `force_recreate` and `grok_bot_vm_bulk` `bulk_recreate`

**Automation:** Team Secrets and group Setup Scripts are ClickOps only — Cursor (the Grok Bot admin plane) exposes no write interface for them. Team Secrets "are not available through the Admin API" and "are managed from the dashboard only" ([Grok Bot for teams and enterprises](https://docs.x.ai/grok-bot/teams-and-enterprises#team-secrets), 2026-10-08), and group Setup Scripts have no route ([Admin API, Grok Bot](https://cursor.com/docs/account/teams/admin-api#grok-bot), 2026-10-08).

No audit event is documented for Team Secrets add, replace or delete; `cloud_agent_secret` covers Cloud Agent secrets only.

{% include pack-code.html vendor="grok-bot" section="3.3" %}

#### Validation & Testing
1. `GET /grok-bot/setup-manifests` shows only reviewed manifests with no literal credentials
2. A dashboard review of every group's **Setup Scripts** finds the same
3. Every `grok_bot_team_setup_manifest` event, and every `grok_bot_group_resource` event with resource `setup_manifest`, maps to an approved change
4. After a recreate (audited as `force_recreate` or `bulk_recreate`), a pilot computer shows the EDR agent running

**Expected result:** Fleet-wide scripts are reviewed, carry no secrets, and install your own endpoint telemetry.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **CIS Controls v8** | 2.7 | Allowlist Authorized Scripts |
| **CIS Controls v8** | 4.1 | Establish and Maintain a Secure Configuration Process |
| **CIS Controls v8** | 10.1 | Deploy and Maintain Anti-Malware Software |
| **NIST 800-53** | CM-3 | Configuration Change Control |
| **NIST 800-53** | CM-5 | Access Restrictions for Change |
| **NIST 800-53** | SI-4 | System Monitoring |
| **NIST 800-53** | IA-5(7) | No Embedded Unencrypted Static Authenticators |
| **SOC 2** | CC8.1 | Change management |
| **SOC 2** | CC6.1 | Logical access security |
| **ISO 27001:2022** | A.8.9 | Configuration management |
| **ISO 27001:2022** | A.8.32 | Change management |
| **ISO 27001:2022** | A.5.17 | Authentication information |
| **Product benchmark** | — | No product benchmark exists yet |

---

## 4. Autonomy & Approvals

### 4.1 Enforce Auto-review with Team Ask-First Rules

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1 |
| NIST 800-53 | AC-3, AC-6, SI-4 |
| OWASP Agentic 2026 | ASI01, ASI09 |
| OWASP LLM Top 10 (2025) | LLM06:2025 |

#### Description
Turn on **Enforce Auto-review**, which is Enterprise only and off by default, then add team **Ask first** rules. Check every group, because a group can lift the lock for its own members.

**What Auto Review does:** Auto Review is "an independent review model". It evaluates shell commands, plugin calls, computer use, automation writes (changes to routines and event triggers) and delegation before they run, and it can let an action proceed, require approval or deny it. Without enforcement, members can turn it off.

**Team Bots:** enforcement "includes Team Bots in chats where nobody can answer an approval, such as teammates' chats and Slack, which otherwise run without Auto-review" ([Cursor: Grok Bot for teams](https://cursor.com/docs/grok-bot/teams)).

**How team rules combine:** team rules apply on top of members' rules, **Ask first** wins on conflict, and team rules stop applying if enforcement is turned off.

**Group opt-out:** a group can lift the lock for its own members with **Don't enforce for this group**. `GET /grok-bot/auto-review` can read `enforced` as `true` while a group has lifted the lock, so the group check is part of this control.

#### Rationale
**Why This Matters:**
- This is the only admin-enforceable approval gate for actions inside the hosted computer; the Execution on Local Computer ceiling (2.4) governs the member's own machine
- It is model-based and "doesn't review every side effect. Memory writes and most settings changes are examples" ([Cursor: Grok Bot security](https://cursor.com/docs/grok-bot/security)), so it complements 2.1, 2.4 and 3.1 rather than replacing them
- Without enforcement, Team Bots in Slack and teammates' chats run without Auto-review, because nobody is there to approve

**Attack Prevented:** Unattended high-impact actions (sends, payments, deletions, production changes) after goal hijack (OWASP Agentic ASI01 Agent Goal Hijack, ASI09 Human-Agent Trust Exploitation; OWASP LLM06:2025 Excessive Agency)

**Real-World Incidents:**
- **Grok–Bankrbot "Morse code" transfer (NeuralTrust analysis by Alessandro Pignati, 2026-05-08), an analogy only:** the attacker first sent a "Bankr Club Membership NFT" to Grok's associated wallet to expand Grok's permissions in the Bankr ecosystem. They then had Grok translate a Morse-code message, and the decoded text instructed Bankrbot to transfer 3 billion DRB tokens (about $150,000) to an attacker-controlled wallet. The system lacked a "human-in-the-loop" mechanism for a payment action.

  This involved xAI's Grok chatbot, not Grok Bot, and predates Grok Bot's 2026-08-11 launch. It illustrates the excessive-agency and prompt-injection pattern that enforced Auto-review with Ask-first payment rules is meant to stop ([NeuralTrust](https://neuraltrust.ai/blog/grok-morse-code))
- **Brave research PoC on Perplexity Comet (2025-08-20):** in a proof-of-concept demonstration, instructions hidden in a Reddit comment made an agentic browser extract the user's email, request a Perplexity OTP, read it in the user's already-signed-in mail, and post both back. Every Bot on a member's computer shares that same signed-in-session primitive ([Brave](https://brave.com/blog/comet-prompt-injection/))

#### Prerequisites
- Cursor Enterprise. Self-serve Teams has no equivalent (see 4.2 and 5.2 for what Teams can do)

#### ClickOps Implementation

**Step 1: Turn on enforcement**
1. Navigate to: **Cursor dashboard** (https://cursor.com/dashboard/bot) → **Grok Bot** page → **Enforce Auto-review** → On

**Step 2: Add team rules**
1. On the same page, select **Configure Rules**
2. Add **Ask first** rules. The vendor's examples are production deployments, external email, payments and accepting legal terms
3. Keep **Allow automatically** rules narrow. Changes save automatically

**Step 3: Check every group**
1. **Members > Groups** → each team-owned group → **Grok Bot** tab → **Agent Capabilities**
2. Confirm **Don't enforce for this group** is not set, because it lifts the team lock for that group's members
3. Review group Auto-review rules too. Group rules "combine with the team's Auto-review rules, with 'Ask first' winning when rules conflict" ([Cursor: Grok Bot for teams](https://cursor.com/docs/grok-bot/teams)). A group **Allow automatically** rule can plausibly widen auto-approval, since group settings only widen, but the exact effect is undocumented, so review every group rule (4.3)

> **Doc conflict: member labels.** Confirm live.
>
> - [Cursor: Grok Bot settings](https://cursor.com/docs/grok-bot/settings) places the Auto-review switch and rules in the **General** > **Bot** section
> - Cursor's [teams](https://cursor.com/docs/grok-bot/teams) and [security](https://cursor.com/docs/grok-bot/security) pages and docs.x.ai say **Settings → General → Auto-review**, where members see team rules as locked rows
> - The changelog's V0.68.0 renames saved rules "Custom Rules"

#### Code Implementation

- **Read:** `GET /grok-bot/auto-review` returns `enforced` plus `rules.allow` and `rules.block`, and is documented as readable on every plan. It returns the team policy only, not a group's **Don't enforce**
- **Write:** `PUT /grok-bot/auto-review` replaces the policy, with up to 20 instructions of 1,000 characters each per list, trimmed and deduped. It returns 403 when Enforce Auto-Review is not available to the team

What the pack does:

- **Verify** GETs the policy and reports a finding when `enforced` is not `true`, or when `rules.allow` and `rules.block` are both empty, because then no team instructions feed Auto Review. Exit 0 means no finding the API can see, not a compliant tenant: group opt-outs are invisible to it, so Validation step 2 is still required
- **Enforce** GETs, then PUTs `enforced` set to `true` while re-sending the stored allow and block lists. That re-send is a precaution, not a documented requirement
- **Why it re-sends:** the doc's "Lock Enforce Auto-Review without changing instructions" example sends empty lists, but it says empty lists keep stored instructions only "if your team can't set Auto-Review rules". For teams that can, the effect of empty lists is undocumented
- **Rule authoring** stays in the dashboard. The UI's **Ask first** and **Allow automatically** map to the API's `block` and `allow` lists only by inference, until a live run confirms the mapping
- **Detection:** the Sigma rule watches the OpenTelemetry stream for `cursor.grok_bot.message_delivery` with `destination_type` `email` and `result` `sent`, which is mail from one of the member's Bot addresses
- **What the rule skips:** drafted emails awaiting approval are destination type `draft`, and sends through a connected Gmail or Outlook plugin are `mcp_tool_call` rows the rule does not select
- **Other signals:** the stream also carries `cursor.grok_bot.tool_decision` (`decision.source` `human`, `policy`, `hook` or `automatic`) and `cursor.grok_bot.guardrail` (`guardrail.kind` `tool_escalation`)
- **Audit:** no `setting_name` for the enforce toggle is documented. `team_settings` may carry it, which needs live validation, and `grok_bot_group_settings` records a group's **Don't enforce** change

{% include pack-code.html vendor="grok-bot" section="4.1" %}

#### Validation & Testing
1. `GET /grok-bot/auto-review` returns `"enforced": true` with the expected rules
2. No group's Grok Bot tab has **Don't enforce for this group** set
3. For a member outside such groups, **Settings → General → Auto-review** shows the team rules locked and cannot be switched off, and a test request to email an outside address produces an approval card
4. Ask a Team Bot in a Slack test thread to take an Ask-first action. Expect it not to run, with a `tool_decision` record (Action Recording on) showing `decision.source` `policy` and no card. Do not assert outcome `held`, which means a card was withdrawn before anyone answered

**Expected result:** Members cannot switch Auto-review off, and Ask-first actions never run unattended.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **CIS Controls v8** | 4.1 | Establish and Maintain a Secure Configuration Process |
| **NIST 800-53** | AC-3 | Access Enforcement |
| **NIST 800-53** | AC-6 | Least Privilege |
| **NIST 800-53** | SI-4 | System Monitoring |
| **SOC 2** | CC6.1 | Logical access security |
| **SOC 2** | CC8.1 | Change management |
| **ISO 27001:2022** | A.5.15 | Access control |
| **ISO 27001:2022** | A.8.9 | Configuration management |
| **OWASP Agentic 2026** | ASI01 | Agent Goal Hijack |
| **OWASP Agentic 2026** | ASI09 | Human-Agent Trust Exploitation |
| **OWASP LLM Top 10 (2025)** | LLM06:2025 | Excessive Agency |
| **Product benchmark** | — | No product benchmark exists yet |

---

### 4.2 Set Required Team Rules for Grok Bot

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1 |
| NIST 800-53 | PL-4, AC-6 |

#### Description
Add a short set of required Team Rules for Grok Bot that cover data handling, external posting and personal-account boundaries. The control is available on Teams and Enterprise, and Team Rules apply to the whole team on both.

**How rules work:** Team Rules are guidance every member's Bots follow, and "Rules applied to Grok Bot are always required, so members cannot turn them off." Keep them short and few; the vendor's example is "never move company data to personal accounts".

**Limits:**

- "Always required" stops members, not admins: an admin or an API key can PATCH a rule to `enabled` `false`
- Rules guide a Bot and are not an approval gate. On Enterprise, pair them with Enforce Auto-review (4.1); on self-serve Teams that pairing is not available

#### Rationale
**Why This Matters:**
- On self-serve Teams, where Enforce Auto-review and Network Controls do not exist, Team Rules are the only org-wide instruction-level policy over Bot behavior. The capability switches in 2.3, 2.4 and 5.1 and the connector policy (2.1) also apply on Teams
- Team Bots in teammates' chats, Slack and group chats act without anyone to approve, and they "follow the same team controls as every Bot, including" Team Rules ([Team Bots](https://docs.x.ai/grok-bot/team-bots))
- A short, required rule set gives every Bot the same data-handling boundary regardless of which member runs it

**Attack Prevented:** Well-intentioned Bots moving company data to personal accounts or posting it where it should not go

#### ClickOps Implementation

**Step 1: Add the rules**
1. Navigate to: **Cursor dashboard** → **Grok Bot** page (https://cursor.com/dashboard/bot)
2. Add each rule and scope it to Grok Bot, or to both Cursor and Grok Bot. The vendor's text is "Add them from the Grok Bot page and scope each rule to Cursor, Grok Bot, or both."
3. The in-UI section and button labels for Team Rules are not documented, so transcribe them live. General Cursor Team Rules have a separate dashboard page (https://cursor.com/dashboard/team-content)

#### Code Implementation

**Routes:**

- `GET /grok-bot/team-rules` lists rules newest first (`id`, `name`, `content`, `enabled`, `scope`), paged at 50 by default and 100 at most, with cursor paging
- `POST /grok-bot/team-rules` requires `name` (1 to 255 characters), `content` (1 to 30,000 characters) and `enabled`, and returns 201; a team can store up to 50 Grok Bot rules
- `PATCH /grok-bot/team-rules/:id` requires at least one field and returns 404 when the rule is missing, and `DELETE` returns 204

**Scope:** there is no scope parameter. API-created rules come back with scope `grokBot`, so the API cannot create a rule scoped to both Cursor and Grok Bot. The doc does not show how a rule scoped to both appears in the list, so the verify region never drops rules that lack scope `grokBot`.

What the pack does:

- **Verify** diffs the list against a reviewed rule file and flags `enabled` `false`
- **Enforce** creates missing reviewed rules and re-enables reviewed rules found disabled, but only when their content still matches the reviewed file
- **Drift:** a disabled rule whose content drifted stays disabled and is reported, because Grok Bot rules are always required and re-enabling it would make unreviewed text binding on every member. Content drift and unexpected rules are reported, never overwritten or deleted
- **Plan reach:** writes are confirmed for Enterprise; Teams-plan reach is unconfirmed (8.6)
- **Detection:** the Sigma rule alerts on `team_rule` with action `delete`, or action `update` with `is_active` `false`
- **Detection caveat:** `team_rule` is the generic Cursor team-rule event, listed under Team settings and integrations rather than in the Grok Bot table, and its payload has no scope field. Its coverage of Grok-Bot-scoped rules is therefore inferred, not documented
- **Group Rules:** they log separately as `grok_bot_group_resource` with resource `rule`

{% include pack-code.html vendor="grok-bot" section="4.2" %}

#### Validation & Testing
1. `GET /grok-bot/team-rules` lists the approved rules with `enabled` `true`, and the verify pack reports no disabled or unexpected rules
2. A member cannot disable the rules in the app

**Expected result:** Every member's Bots carry the same required data-handling rules.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **CIS Controls v8** | 4.1 | Establish and Maintain a Secure Configuration Process |
| **NIST 800-53** | PL-4 | Rules of Behavior |
| **NIST 800-53** | AC-6 | Least Privilege |
| **SOC 2** | CC2.2 | Internal communication of information security responsibilities |
| **SOC 2** | CC6.1 | Logical access security |
| **ISO 27001:2022** | A.5.10 | Acceptable use of information and other associated assets |
| **Product benchmark** | — | No product benchmark exists yet |

---

### 4.3 Audit Group Grok Bot Tabs for Widening Overrides

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1, 8.11 |
| NIST 800-53 | CM-3, CM-6, AU-6 |

#### Description
Keep every group's Grok Bot tab at the team value unless an exception is approved and recorded, and review the tabs on a schedule and on every group-settings audit event. Enterprise only.

**How group settings combine:** "Group settings only widen: a group can grant its members more than the team allows, never less, and a member in several groups gets the most permissive result."

**What a group tab can change:**

- re-allow Cloud Agents
- raise the local-execution ceiling
- re-enable local egress
- lift Enforce Auto-review with **Don't enforce for this group**
- add group Auto-review rules, which combine with the team's, with **Ask first** winning on conflict. A group **Allow automatically** rule can plausibly widen auto-approval, but the exact effect is undocumented, so review every group rule

**Network works differently:** a group's network policy "replaces the team's for their members" unless the team policy is locked (**Lock for All Groups**), and the docs do not say how several group network policies combine.

**Where to tighten:** tighten controls on the Grok Bot page (2.3, 2.4, 3.1, 3.2, 4.1) and lock the network policy (3.1).

#### Rationale
**Why This Matters:**
- One group override undoes team-wide hardening for its members, and it is invisible on the team-level Grok Bot page; on Enterprise it is audit-logged
- For SCIM-synced directory groups, membership is managed in the IdP and Cursor shows it read-only, so who a group's overrides reach is decided outside Cursor
- No API reads a group tab's current state, so only a dashboard review proves it

**Attack Prevented:** Control erosion through permissive group exceptions

#### ClickOps Implementation

**Step 1: Review each group tab**
1. Navigate to: **Cursor dashboard** → **Members > Groups** (https://cursor.com/dashboard/members?subtab=groups) → [a group your team owns] → **Grok Bot** tab
2. **Agent Capabilities:** Cloud Agents, the Execution on Local Computer ceiling, Allow Local Egress, Auto-review's **Don't enforce for this group**, and group Auto-review rules
3. **Network:** the group's own policy, labelled **Group Network Access**
4. **Group Rules** and **Setup Scripts**
5. Reset anything that differs from the team value unless a recorded exception covers it

**Step 2: Lock the network policy**
1. On the Grok Bot page's **Network** section, turn on **Lock for All Groups** (3.1)

> **Doc conflict: tab label.** The SCIM doc names the members tab **Members & Groups** with a **Directory Groups** subtab ([SCIM](https://cursor.com/docs/account/teams/scim)), while the Grok Bot doc says **Members > Groups**. Confirm the label live.

#### Code Implementation

**Automation:** ClickOps only — Cursor (the Grok Bot admin plane) exposes no write interface for this setting ([Admin API, Grok Bot](https://cursor.com/docs/account/teams/admin-api#grok-bot), 2026-10-08). The pack below is read-only verification.

- **No group route:** no route reads or writes a group's Grok Bot tab. All 17 Grok Bot routes are team-level, the team directory-group routes carry no Grok Bot fields, and the Organization API has only computer operations
- **The one neutralizing write:** `PUT /grok-bot/network` with `locked` set to `true` (3.1) neutralizes a group override, and it covers network only

What the pack reads:

- **Audit events** from `GET /teams/audit-logs`. The API defaults to 7 days and allows at most 30 days per request and 500 events per page, and retention is undocumented. The pack looks back 30 days by default (`HTH_LOOKBACK_DAYS`) and walks consecutive 30-day windows of `grok_bot_group_settings` and `grok_bot_group_resource`
- **The network lock:** it also reports `locked` from `GET /grok-bot/network`, which is readable on every plan
- **Organization scope:** with `HTH_AUDIT_SCOPE=org` it requires `CURSOR_TEAM_ID`, so events from other linked teams are not mixed into the one team whose lock it checks

**What it cannot see:** the pack detects changes, not current state. An override set before the window cannot be seen through any API, so exit 0 is not a compliant tenant and the dashboard review in Validation step 1 is still required.

- `setting_name` values are not enumerated, so whether group network-policy and group Auto-review-rule edits land in `grok_bot_group_settings` is undocumented
- Payloads never carry Group Rule or Setup Script text

**Detection:** a Sigma rule alerts on both event types.

{% include pack-code.html vendor="grok-bot" section="4.3" %}

#### Validation & Testing
1. Only a dashboard review proves current state: every group's Grok Bot tab matches the team values or has a recorded exception
2. `GET /grok-bot/network` returns `"locked": true`
3. The read pack shows no unexplained `grok_bot_group_settings` or `grok_bot_group_resource` events in the window

**Expected result:** No group widens a team control without a recorded exception.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **CIS Controls v8** | 4.1 | Establish and Maintain a Secure Configuration Process |
| **CIS Controls v8** | 8.11 | Conduct Audit Log Reviews |
| **NIST 800-53** | CM-3 | Configuration Change Control |
| **NIST 800-53** | CM-6 | Configuration Settings |
| **NIST 800-53** | AU-6 | Audit Record Review, Analysis, and Reporting |
| **SOC 2** | CC7.2 | Monitoring of system components for anomalies |
| **SOC 2** | CC8.1 | Change management |
| **ISO 27001:2022** | A.8.9 | Configuration management |
| **Product benchmark** | — | No product benchmark exists yet |

---

## 5. Sharing & Team Bots

### 5.1 Keep Public Template Sharing Off

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 3.3 |
| NIST 800-53 | AC-21, AC-3 |

#### Description
Turn the team's public template sharing policy off, so sharing stays team-only. The dashboard setting is available on Teams and Enterprise.

**What a template carries:** a Bot template carries the Bot's identity, description, skills and routines, and "A public link can be opened by anyone who has it" ([Create and manage Bots](https://docs.x.ai/grok-bot/bots)).

**Defaults:**

- **Team policy:** "Enterprise teams start with public sharing off; other teams start with it allowed" ([Cursor: public template sharing](https://cursor.com/docs/grok-bot/teams#public-template-sharing))
- **Per-link default:** a separate setting. "Accounts on an Enterprise plan default to **Team-only**; other accounts default to a public link" (Create and manage Bots)

**Enforcement:** "Cursor enforces the policy on its servers, including for templates that are already public." Group Grok Bot tabs cannot widen this setting, because their Agent Capabilities list omits it, so the team value is authoritative.

**Vendor guidance:** the vendor's recommended configuration says "Keep public template sharing off unless members should publish Bot templates outside the team".

#### Rationale
**Why This Matters:**
- Skills and routines encode internal processes and system names, and they can embed credentials
- Non-Enterprise teams start with public links allowed
- Even within the team, members should "Remove API keys, internal URLs, customer data, and anything else you would not put in a public document" before sharing

**Attack Prevented:** Leakage of internal workflows and embedded secrets through public template links


#### ClickOps Implementation

**Step 1: Turn public sharing off**
1. Navigate to: **Cursor dashboard** → **Grok Bot** page (https://cursor.com/dashboard/bot)
2. Set public template sharing to Off. The doc groups the setting under its Agent capabilities heading and gives no bolded in-UI label, so confirm the exact label live

#### Code Implementation

- **Verify:** the verify region reads `templateSharing` from `GET /grok-bot/capabilities` (`all`, `team_only`, `none` or `null`). It treats `null` as non-compliant, because `null` restores the team default, which is allowed on non-Enterprise teams
- **Enforce:** the enforce region sends `PATCH /grok-bot/capabilities` with `{"templateSharing": "team_only"}`, which matches the doc's "Off keeps sharing team-only"
- **The value `none`:** it is listed but never defined, so verify exits 2 (not judged) on it until a live test shows it blocks public links, and enforce never overwrites it
- **Plan reach:** writes are confirmed for Enterprise; no page says `/capabilities` works on Teams, so verify live on a Teams tenant (8.6)
- **Detection:** the Sigma rule alerts on `grok_bot_resource` with `resource_type` `template` and `visibility` `PUBLIC`. Streamed audit events nest these fields under a key named after the event type, while Admin API pulls use `event_data`
- **Blind spots:** payloads never include template bodies, so a SIEM cannot see secrets inside templates, and no `setting_name` for the sharing policy itself is documented

> **Undocumented values:** the Admin API does not define `none`, and does not say which value the dashboard's Off maps to. The pack enforces `team_only` and reports `none` as unjudged.

{% include pack-code.html vendor="grok-bot" section="5.1" %}

#### Validation & Testing
1. `GET /grok-bot/capabilities` returns `templateSharing` `team_only` (or `none` once confirmed live to block public links), never `all` or `null`
2. A previously public template link no longer opens for a non-member
3. **Enterprise:** there are no `grok_bot_resource` events with visibility `PUBLIC`

**Expected result:** Bot templates can be shared only inside the team.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **CIS Controls v8** | 3.3 | Configure Data Access Control Lists |
| **NIST 800-53** | AC-21 | Information Sharing |
| **NIST 800-53** | AC-3 | Access Enforcement |
| **SOC 2** | CC6.1 | Logical access security |
| **SOC 2** | C1.1 | Identification and maintenance of confidential information |
| **ISO 27001:2022** | A.5.14 | Information transfer |
| **Product benchmark** | — | No product benchmark exists yet |

---

### 5.2 Govern Team Bots, Their Shared Credentials, and Their Slack Apps

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 3.3, 6.8 |
| NIST 800-53 | AC-6, AC-21, IA-5 |
| OWASP Agentic 2026 | ASI01, ASI06, ASI07 |

#### Description
Govern which Team Bots exist, who reaches them and which credentials they carry. A Team Bot shares one member's plugins, secrets, skills, files and team memory with every teammate and with Slack, and admins cannot change any of that.

**Status:** Team Bots are in public beta on Teams and Enterprise ([xAI launch post](https://x.ai/news/team-bots), 2026-09-28); the docs pages carry no beta label, and Cursor's help notes Team Bots may not yet be on for every team.

- **What is shared:** "The Bot can use every secret in any teammate's conversation", and a plugin configured with a key is "The Bot's own credential, the same for everyone" ([Team Bots](https://docs.x.ai/grok-bot/team-bots)). Slack channels, group DMs and threads use "One shared computer for that Bot", and posts from Slack workflows and other apps are exempt from the account-linking requirement
- **Bot-to-Bot traffic:** a teammate's published Team Bot can be added to a group chat, and a Bot can "message another Bot to hand off work". Of stopping that, Cursor says "There is no switch for this"; the only lever is an instruction in the group's or the Bot's description, such as "Don't message other Bots. Ask me first." ([Cursor help: group chats](https://cursor.com/help/grok-bot/group-chats))
- **Who can change a Team Bot:** xAI says "Only the Bot's owner and its managers change its plugins, secrets, skills, and files"; Cursor's help says only the owner can change a Team Bot (8.6)
- **What admins cannot do:** change those settings, or call a Team Bot API. No documented admin control disables Team Bot creation (as of 2026-10-09)
- **The admin levers:** Manage Team Bots (default assignment and delete), Slack's own app approval, the connector policy (2.1), Team Rules (4.2) and, on Enterprise, Enforce Auto-review (4.1)

Require owners to use "scoped, read-only service-account keys instead of personal credentials", and to choose Remote HTTPS rather than a Command custom MCP server when secrets are involved.

#### Rationale
**Why This Matters:**
- A Team Bot turns one member's credentials and memory into a team-wide, Slack-reachable agent, and its team memory "is read by every teammate's conversation" ([Team Bots](https://docs.x.ai/grok-bot/team-bots))
- Auto Review "doesn't review every side effect. Memory writes and most settings changes are examples" ([Cursor: Grok Bot security](https://cursor.com/docs/grok-bot/security)), so a poisoned team memory is not caught at write time
- On self-serve Teams, Enforce Auto-review does not exist, so Team Bots in teammates' chats and Slack always run without Auto-review where nobody can approve. On Enterprise, a group can also lift enforcement with **Don't enforce for this group**

**Attack Prevented:** Indirect prompt injection from Slack content hijacking a shared Team Bot to exfiltrate shared data (OWASP Agentic ASI01 Agent Goal Hijack), poisoned team memory that every teammate's conversation reads (ASI06 Memory & Context Poisoning), and instructions relayed to a Team Bot by other Bots or by Slack workflow and app posts that skip account linking (ASI07 Insecure Inter-Agent Communication). The levers here limit which Team Bots exist and who reaches them; nothing stops Bot-to-Bot messaging itself

**Real-World Incidents:**
- **PromptArmor (August 2024):** an injection posted in a public Slack channel made Slack AI exfiltrate data from private channels the attacker was not in. Team Bots answer channel threads and workflow posts on one shared computer ([PromptArmor](https://www.promptarmor.com/resources/data-exfiltration-from-slack-ai-via-indirect-prompt-injection))
- **Radware ZombieAgent (Zvika Babo, 2026-01-08):** instructions written into ChatGPT's memory persisted across new chats and kept exfiltrating later conversations. This is the risk class for Team Bot team memory, which Auto Review does not review ([Radware](https://www.radware.com/blog/threat-intelligence/zombieagent/); read in a real browser on 2026-10-08)

#### Prerequisites
- Cursor Teams or Enterprise with Team Bots turned on for the team
- Slack workspace app approval kept on ([slack 3.1](/guides/slack/#31-restrict-app-installation-and-approval))

#### ClickOps Implementation

**Step 1: Set default assignment for each Team Bot**
1. Navigate to: **Cursor dashboard** (https://cursor.com/dashboard/bot) → **Grok Bot** page → **Team Bots** → **Manage Team Bots** ([Team Bots: Add Team Bots for members by default](https://docs.x.ai/grok-bot/team-bots#add-team-bots-for-members-by-default))
2. For each Team Bot, choose **All team**, **None** or specific groups. Groups come from **Members & Groups**
3. Assignment only controls whose sidebar the Bot is forced into; those members see "Required by your admin. You can't turn this off." **None** does not restrict access: after a Bot is published, any teammate can still add it from **New** → **Team Bots**, from search, or from a link ([Cursor help: Team Bots](https://cursor.com/help/grok-bot/team-bots)). To remove an unapproved Bot, delete it (Step 2)

**Step 2: Delete unapproved Team Bots**
1. In **Manage Team Bots**, choose the trash icon on the Bot's row → type the Bot's exact name → **Delete** ([Team Bots: Delete a Team Bot as an admin](https://docs.x.ai/grok-bot/team-bots#delete-a-team-bot-as-an-admin))
2. Deleting removes the Bot's Slack app. "If the Slack app can't be removed, a Slack workspace admin can remove it in Slack"

**Step 3: Keep Slack's gate on**
1. Keep workspace app approval on in Slack, so Team Bot setup stops at **Awaiting admin approval** until a Slack admin approves the Team Bot's app

**Step 4: Narrow who can create Team Bots (Enterprise)**
1. No documented admin control disables Team Bot creation (as of 2026-10-09). On Enterprise, Manage Group Access (1.1) limits it indirectly by limiting who has Grok Bot at all. Ask your Cursor account team whether Team Bots can be kept off for a team

**Step 5: Keep each Team Bot's managers to a minimum (owner action)**
1. In the Bot's details → **Setup** → **Managers**, the owner removes anyone who no longer needs to change the Bot: trash icon (**Remove manager**) → **Remove**
2. A manager "can change the Bot's setup, like its profile, skills, plugins, secrets, and Slack app", while "Publishing, unpublishing, and deleting the Bot stay with" the owner ([Team Bots: Add managers](https://docs.x.ai/grok-bot/team-bots#add-managers))
3. As an HTH process recommendation, because no audit event records manager changes, have each owner attest their Managers list at every Team Bot review. No page documents an admin view of a Bot's managers

#### Code Implementation

**Automation:** ClickOps only — Cursor (the Grok Bot admin plane) exposes no write interface for this setting ([Admin API, Grok Bot](https://cursor.com/docs/account/teams/admin-api#grok-bot), 2026-10-08). The Grok Bot section has no Team Bot route, no capabilities field toggles Team Bots, and Manage Team Bots and admin delete are dashboard-only. The pack below is read-only verification.

The pack is an inventory, Enterprise only because audit logs are an Enterprise feature.

- **Events:** from `GET /teams/audit-logs`, it pulls `grok_bot_created` (with `source` `direct`, `template`, `agent_sdk` or `system`), `grok_bot_lifecycle` (including `published`, `unpublished` and `delete`), `grok_bot_skill` and `slack_account_link`
- **Organization-wide variant:** `GET /organizations/audit-logs` with an Organization key holding `auditlogs:read`
- **Detection:** a Sigma rule alerts on `grok_bot_lifecycle` with action `published`
- **Not audited:** no documented audit event covers Manage Team Bots default assignment, adding or removing managers, Team Bot secrets, plugins or files, or the creation and removal of a Team Bot's Slack app
- **Plugin claim:** the [Grok Bot changelog](https://x.ai/changelog/bot) V0.57.0 says audit logs now record plugins, but the event table has no Grok Bot plugin event (8.6)

{% include pack-code.html vendor="grok-bot" section="5.2" %}

#### Validation & Testing
1. **Manage Team Bots** lists only approved Team Bots with the intended assignment. This half can only be checked in the dashboard
2. Every `grok_bot_lifecycle` `published` event maps to an approved request
3. Slack's app list shows Team Bot apps only for approved Bots

**Expected result:** Every Team Bot is approved, assigned deliberately, and visible in Slack only through an approved app.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **CIS Controls v8** | 3.3 | Configure Data Access Control Lists |
| **CIS Controls v8** | 6.8 | Define and Maintain Role-Based Access Control |
| **NIST 800-53** | AC-6 | Least Privilege |
| **NIST 800-53** | AC-21 | Information Sharing |
| **NIST 800-53** | IA-5 | Authenticator Management |
| **SOC 2** | CC6.1 | Logical access security |
| **SOC 2** | CC6.3 | Role-based access, modification and removal |
| **ISO 27001:2022** | A.5.15 | Access control |
| **ISO 27001:2022** | A.5.17 | Authentication information |
| **OWASP Agentic 2026** | ASI01 | Agent Goal Hijack |
| **OWASP Agentic 2026** | ASI06 | Memory & Context Poisoning |
| **OWASP Agentic 2026** | ASI07 | Insecure Inter-Agent Communication |
| **Product benchmark** | — | No product benchmark exists yet |

---

## 6. Monitoring & Audit

### 6.1 Turn On Action Recording and Export It over OpenTelemetry

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 8.2, 8.5, 8.9 |
| NIST 800-53 | AU-2, AU-3, AU-12, SI-4 |
| OWASP Agentic 2026 | ASI10 |

#### Description
Turn on Action Recording and OpenTelemetry Export, and route both to the SIEM. Action Recording is Enterprise only and off by default.

**What it records:** audit logs record control-plane changes, not what Bots did. Action Recording records sanitized metadata for each tool call and decision:

- MCP calls
- shell commands (secret-scrubbed, at most 8 KiB)
- browser navigations as `scheme://host/path` with query strings, fragments and credentials stripped
- computer-use counts, file transfers, messages sent and routine runs
- guardrail interventions, and subagent and Cloud Agent handoffs

**Where events go:** events are kept in an internal store with 90-day retention ([Grok Bot security](https://docs.x.ai/grok-bot/security)), and "Recorded events do not appear on the Audit Log page." OpenTelemetry Export is "the customer path for Action Recording events", tagged `cursor.surface=grok_bot`.

**Endpoint:** it must be reachable from the public internet. Cursor sends from a fixed set of source IPs you can allowlist, but "Use TLS and auth as the primary control" ([OpenTelemetry Export](https://cursor.com/docs/enterprise/opentelemetry-export)).

**Caveats:** turning a toggle back on never backfills. Privacy Mode (Legacy) forces recording off and blocks Grok Bot entirely.

**L3 option:** conversation content export, only where content-level forensics are required.

- It covers prompt and response text (capped at 32 KiB per message) and hosted-connector MCP Tool I/O (capped at 8 KiB per side); `stdio` servers and built-in tools report no payloads
- Redaction is pattern-based, and "your team owns that residual risk"
- The `conversation_content` family covers Cloud Agents and Grok Bot together ("Cloud Agents and Grok Bot only"), and there is no Grok-Bot-only toggle. Turning it on also exports Cloud Agent conversation text, so weigh that in the data-minimization review

#### Rationale
**Why This Matters:**
- Grok Bot "does not ship a built-in customer-facing telemetry or EDR feed" (Team Setup can install your own; see 3.3), and "Dedicated data loss prevention hooks are not available"
- Bots act as the signed-in member, so a target app's identity record is the member's, except where team-managed connectors use team or service-account credentials
- By default, hosted-computer traffic leaves from shared static egress ranges, which the vendor says to "treat ... as identifying Grok Bot traffic rather than your team alone" ([Grok Bot security](https://docs.x.ai/grok-bot/security)); the ranges come from your account team
- A source-IP check can therefore flag Grok Bot computer traffic, but it cannot say which customer, member or Bot sent it, or separate a Bot's step from a member who took control of the computer to sign in
- With Allow Local Egress (3.2), destinations see the member's desktop IP instead, and with a Team Setup networking client (3.3), your network's addresses. Connector tokens stay on Cursor's backend, and the docs give no source address for connector calls
- These events are the only record of agent behavior

**Attack Prevented:** Undetected agent misuse, and actions that cannot be attributed to a Bot rather than a person (OWASP Agentic ASI10 Rogue Agents)

#### Prerequisites
- Cursor Enterprise, not on Privacy Mode (Legacy)
- An OTLP/HTTP collector reachable from the public internet over HTTPS

#### ClickOps Implementation

**Step 1: Turn on Action Recording**
1. Navigate to: **Cursor dashboard** → **Grok Bot** page (https://cursor.com/dashboard/bot) → **Action Recording** → On

**Step 2: Create an OpenTelemetry destination**
1. **Team Settings** → **OpenTelemetry Export** → **Create destination**
2. Enter the HTTPS base URL with no `/v1` suffix (Cursor appends `/v1/metrics` and `/v1/logs`) and an auth header such as `Authorization: Bearer <token>`
3. **Test connection** → **Enable**
4. Keep the `grok_bot_agent_actions` family toggle on. It defaults on for a new destination but can be turned off ([OpenTelemetry Export](https://cursor.com/docs/enterprise/opentelemetry-export))
5. Keep the `skills_hooks_plugins` family on too: a Bot's skill reads arrive as `cursor.skill.activated` in that family, and they are Action Recording data

**Step 3 (L3, optional): Conversation content**
1. **Team Settings** → **OpenTelemetry Export** → **Allow conversation content export**
2. On the destination, turn on **Conversation content**. That turns on **Prompts** and **Responses**; **Tool I/O** stays off until you turn it on

> **Changelog vs docs:** the changelog's V0.30.0 says "Action Recording on the dashboard records members' Grok Bot actions to your team's audit log". The current docs say "Recorded events do not appear on the Audit Log page" and route them through OpenTelemetry only. Under this repository's fact-dispute rule the current docs win; confirm live.

#### Code Implementation

- **Verify:** the verify region reads `actionRecording` from `GET /grok-bot/capabilities` (`read:*` or `admin:*`)
- **Enforce:** the enforce region sends `PATCH /grok-bot/capabilities` with `{"actionRecording": true}` (Enterprise, `admin:*`, 403 when the field is not available)
- **Result line:** with `actionRecording` `true` the pack's result line reads "NOT proven: the OpenTelemetry destination" rather than "compliant", because with no destination nothing leaves Cursor

**Automation:** the OpenTelemetry destination and conversation content export are ClickOps only — Cursor (the Grok Bot admin plane) exposes no write interface for them: the team Admin API, the Organization API and the API overview document no OpenTelemetry route ([Admin API, Grok Bot](https://cursor.com/docs/account/teams/admin-api#grok-bot), 2026-10-08).

**Drift signal:** the only API-side drift signal is the audit log, which the 6.2 pack pulls ([Compliance and monitoring](https://cursor.com/docs/enterprise/compliance-and-monitoring), 2026-10-09):

- `customer_telemetry_destination`: a destination created, updated or deleted, with `enabled`, `enabled_families` and `disabled_families`
- `customer_telemetry_content_opt_in`: conversation-content export turned on or off

A destination deleted or misconfigured before the audit window is not visible that way.

On the wire, records arrive as OTLP/HTTP binary protobuf POSTed to `<base>/v1/logs`. The `grok_bot_agent_actions` family covers `cursor.grok_bot.mcp_tool_call`, `shell_command`, `browser_navigation`, `computer_use_session`, `tool_result`, `tool_decision`, `file_transfer`, `message_delivery`, `routine_run`, `guardrail` and `delegation` ([Wire Reference](https://cursor.com/docs/enterprise/opentelemetry-export/wire)).

{% include pack-code.html vendor="grok-bot" section="6.1" %}

#### Validation & Testing
1. `GET /grok-bot/capabilities` returns `"actionRecording": true`
2. The collector receives logs with `cursor.surface=grok_bot`
3. A test shell command from a pilot Bot arrives as log event `cursor.grok_bot.shell_command`. Route on the event name, since the body is the constant `grok_bot_shell_command`

**Expected result:** Every Bot action reaches your SIEM as sanitized metadata.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **CIS Controls v8** | 8.2 | Collect Audit Logs |
| **CIS Controls v8** | 8.5 | Collect Detailed Audit Logs |
| **CIS Controls v8** | 8.9 | Centralize Audit Logs |
| **NIST 800-53** | AU-2 | Event Logging |
| **NIST 800-53** | AU-3 | Content of Audit Records |
| **NIST 800-53** | AU-12 | Audit Record Generation |
| **NIST 800-53** | SI-4 | System Monitoring |
| **SOC 2** | CC7.2 | Monitoring of system components for anomalies |
| **SOC 2** | CC7.3 | Evaluation of security events |
| **ISO 27001:2022** | A.8.15 | Logging |
| **ISO 27001:2022** | A.8.16 | Monitoring activities |
| **OWASP Agentic 2026** | ASI10 | Rogue Agents |
| **Product benchmark** | — | No product benchmark exists yet |

---

### 6.2 Monitor Grok Bot Control-Plane Audit Events

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 8.2, 8.9, 8.11 |
| NIST 800-53 | AU-2, AU-6, SI-4 |

#### Description
Pull the Grok Bot audit events on a schedule or have them streamed, alert on the posture-changing types, and give routines their own alert. Select events by event type, never by application alone.

**The event set:**

- **Grok Bot control-plane table:** Enterprise audit logs carry `sand_onboarding`, `grok_bot_created`, `grok_bot_lifecycle`, `grok_bot_access_changed`, `grok_bot_team_setup_manifest`, `grok_bot_group_settings`, `grok_bot_group_resource`, `grok_bot_resource`, `grok_bot_skill`, `grok_bot_machine`, `grok_bot_vm`, `grok_bot_vm_bulk` and `grok_bot_routine`
- **Two more:** the Grok Bot docs also count `mcp_authentication` and `slack_account_link` as Grok Bot control-plane events
- **Telemetry events:** `customer_telemetry_destination` and `customer_telemetry_content_opt_in` belong in the same review, because they record someone blinding 6.1

**Actors:** actors appear as `Bot: <owner email>` when a Bot acts during its owner's turn, and as `System` for Grok Bot events with no identified actor.

**Why not filter by application:** `application_type` is `grok_bot` only when the Grok Bot surface acted, and admin changes made in the dashboard or through the Admin API carry `cursor`, so select by event type, not by `application_type` alone.

**Scope:** [cursor 10.1](/guides/cursor/#101-enable-cursor-usage-logging) covers generic audit export; this control is the Grok Bot event set.

#### Rationale
**Why This Matters:**
- Several posture changes have no preventive admin control or are made by members, so detection is the remaining control. They include widened access, group overrides, Team Setup edits, public templates, Team Bot publication and routine creation
- Routines run unattended on a schedule, or "when something happens, such as a Slack message, a GitHub, Linear, Sentry, or PagerDuty event, an email, or a webhook call". Slack triggers can watch one channel or all of Slack, including "on any message", and webhook senders pass `Authorization: Bearer <key>` ([Cursor help: Routines](https://cursor.com/help/grok-bot/routines))
- Every one of those triggers is untrusted input. There is no routine-specific admin control, and members create, edit, pause and delete them
- `grok_bot_routine` is the only default-on, control-plane record of routine create, update, enable, disable and delete. Routines are edited in place, so an `update` can repoint an existing routine at a broader trigger or a new instruction
- The nearest preventive lever is Enforce Auto-review with team rules (4.1), since Auto Review covers automation writes; those approvals go to the member, not the admin

**Attack Prevented:** Unnoticed persistence through routines, and configuration drift

#### Prerequisites
- Cursor Enterprise and admin access ([Compliance and monitoring](https://cursor.com/docs/enterprise/compliance-and-monitoring))

#### ClickOps Implementation

**Step 1: Review in the dashboard**
1. Navigate to: **Cursor dashboard** → **Audit Log** page (https://cursor.com/dashboard/audit-log)
2. Filter by event type, using the Grok Bot event types listed in the Description plus `mcp_authentication`, `slack_account_link` and the two `customer_telemetry_*` types, and add a date range or actor if you need one. Do not filter by application alone:
   - Admin changes made on the Grok Bot page of the Cursor dashboard, on a group's Grok Bot tab, or through the Admin API carry application `cursor`, not `grok_bot` ("`cursor` for … cursor.com, and the Admin API", [Compliance and monitoring](https://cursor.com/docs/enterprise/compliance-and-monitoring))
   - That includes enabling Grok Bot, Manage Group Access, Team Setup and group settings
   - An application filter of Grok Bot is useful only as an extra view of actions the Grok Bot surface itself took
3. Export the filtered result to CSV; the export includes an **Application** column

**Step 2: Stream to the SIEM**
1. Set up streaming as in [cursor 10.1](/guides/cursor/#101-enable-cursor-usage-logging); Cursor arranges it by contact (hi@cursor.com). Route the event types in Step 1 to the Grok Bot alerts below

**Step 3: Add per-run routine visibility**
1. Per-run visibility needs Action Recording plus OpenTelemetry Export (6.1): `cursor.grok_bot.routine_run` events. Select routine-started turns on the always-present resource attribute `cursor.entrypoint` = `automation`, with `cursor.grok_bot.initiated_by` = `routine` as a secondary check, since that attribute is optional and absent from older Grok Bot versions ([Wire Reference](https://cursor.com/docs/enterprise/opentelemetry-export/wire))

#### Code Implementation

**Automation:** ClickOps only — Cursor (the Grok Bot admin plane) exposes no write interface for this setting ([Compliance and monitoring](https://cursor.com/docs/enterprise/compliance-and-monitoring), 2026-10-08). Audit logging has no documented enable or disable control and no streaming configuration endpoint, and streaming is arranged by contacting Cursor. The pack below is read-only verification.

The pack calls `GET /teams/audit-logs` ([Admin API: audit logs](https://cursor.com/docs/account/teams/admin-api#get-audit-logs)) with a Team key, or `GET /organizations/audit-logs` with an Organization key holding `auditlogs:read` or `admin:*`.

- **Parameters:** `startTime`, `endTime`, `eventTypes`, `search`, `users`, `page` and `pageSize`. There is no `application_type` filter parameter
- **Limits:** the API defaults to 7 days and allows at most 30 per request, at 500 events per page and 20 requests per minute, oldest first
- **Event set:** the Grok Bot event types plus `mcp_authentication`, `slack_account_link`, `customer_telemetry_destination`, `customer_telemetry_content_opt_in` and `team_settings`, pulled in 30-day windows as JSONL. Every row is selected by `event_type`; the pack counts `application_type` for context and never uses it to select or drop rows
- **Flags:** posture-changing rows, including routine `create`, `update` and `enable` (a routine is edited in place, so an update can repoint a benign routine at a broad trigger), every `customer_telemetry_destination` change (a delete or `enabled` `false` blinds 6.1) and every conversation-content opt-in change
- **Review block:** `team_settings` rows whose `setting_name` is not one of the documented common names are listed separately, unflagged. Team-wide Grok Bot toggles may land there, because the event fires for changes "including changes made through the Admin API" and its name list is "not an exhaustive list", but no Grok Bot `setting_name` is documented
- **Routine rule:** one Sigma rule alerts on `grok_bot_routine` with action `create`, `update` or `enable`; `trigger_type` values are not enumerated, so it does not filter on them
- **Telemetry rule:** a second alerts on `customer_telemetry_destination` with action `delete` or `enabled` `false`, and on `customer_telemetry_content_opt_in` with `enabled` `true`, all documented field values

{% include pack-code.html vendor="grok-bot" section="6.2" %}

#### Validation & Testing
1. The pack exports the Grok Bot event set for the window, and its count for each event type matches the Audit Log page filtered by the same event type over the same window
2. Creating a test routine fires the SIEM alert within the pull or stream interval, and so does editing it

**Expected result:** Every Grok Bot posture change and every new routine reaches the SIEM.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **CIS Controls v8** | 8.2 | Collect Audit Logs |
| **CIS Controls v8** | 8.9 | Centralize Audit Logs |
| **CIS Controls v8** | 8.11 | Conduct Audit Log Reviews |
| **NIST 800-53** | AU-2 | Event Logging |
| **NIST 800-53** | AU-6 | Audit Record Review, Analysis, and Reporting |
| **NIST 800-53** | SI-4 | System Monitoring |
| **SOC 2** | CC7.2 | Monitoring of system components for anomalies |
| **ISO 27001:2022** | A.8.15 | Logging |
| **ISO 27001:2022** | A.8.16 | Monitoring activities |
| **Product benchmark** | — | No product benchmark exists yet |

---

## 7. Lifecycle & Containment

### 7.1 Offboard Completely: Delete Computer Data, Remove Access, Revoke Sessions

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 5.3, 6.2 |
| NIST 800-53 | AC-2, PS-4, MP-6 |

#### Description
Offboard in three steps, in order: on Enterprise, delete the member's computer data while they are still on the team; remove their access on every team linked to the organization; then revoke their IdP sessions.

**Why terminating is not enough:** terminating a computer, manually or automatically, ends current work but keeps the durable disk with the member's Bots, files and logins: "None of these remove access" ([Grok Bot for teams and enterprises](https://docs.x.ai/grok-bot/teams-and-enterprises)).

**The three parts, in order:**

1. **Delete computer data (Enterprise).** Do it while the member is still on the team. It works only for current members: "Every ID must belong to a current member of the team who has signed in to Cursor; if one doesn't, the request returns 400 and nothing starts"
2. **Remove access** by team removal, SCIM deprovisioning ([cursor 1.4](/guides/cursor/#14-enable-scim-provisioning-enterprise)) or group removal. Remove the member from every team linked to the organization, because one computer spans all of them
3. **Revoke the member's IdP sessions**, because application sessions persist on the computer until revoked

#### Rationale
**Why This Matters:**
- The durable disk keeps "local files, browser sessions, and anything saved in the browser", and command-line credentials are shared across all of a member's Bots on that computer. "Deleting a Bot doesn't remove computer files or browser sessions." ([Cursor: Grok Bot security](https://cursor.com/docs/grok-bot/security))
- Connector OAuth tokens stay on Cursor's backend ("tokens are never stored on the computer"), so revoke those grants at each source service
- Once a member is gone, no admin path to delete their durable data is documented. The fallback is the DPA, under which data is "deleted or returned within 30 days of written direction after the service ends"

**Attack Prevented:** Orphaned standing sessions and credentials on a departed member's hosted computer

#### Prerequisites
- **Enterprise:** an organization admin for **Manage Bot Computers**, or an Organization API key with `admin:*` and computer operations turned on for the team by the account team
- **Self-serve Teams:** admins have no documented data-deletion path, because Manage Bot Computers is Enterprise only. Individual-plan users delete through Cursor's account settings flow under the applicable Cursor terms
- **Team Bots the leaver owns:** the Team Bots docs do not say what happens to a Team Bot when its owner leaves the team, and they offer no ownership transfer. Managers can change a Bot's setup, but "Publishing, unpublishing, and deleting the Bot stay with" the owner ([Team Bots](https://docs.x.ai/grok-bot/team-bots))
- **Owner dependencies:** several parts of a Team Bot depend on the owner. Its Slack setup "uses the owner's Slack connection", and Slack posts from unlinked senders "count against the owner"
- **Before removing a member:** list the Team Bots they own in Manage Team Bots, and have the owner delete each one or delete it as an admin (trash icon, type the exact name, **Delete**). Admin deletion also removes the Bot's Slack app; "If the Slack app can't be removed, a Slack workspace admin can remove it in Slack."
- **Do not rely on Unpublish:** only the owner can publish again, so a Bot unpublished by a departing owner can afterwards only be deleted (5.2, 8.6)

#### ClickOps Implementation

Run the steps in this order.

**Step 1: Delete the data first, while the member is still on the team (Enterprise, organization admins)**
1. Navigate to: **Cursor dashboard** → **Grok Bot** → **Bot Computers** → **Manage Bot Computers** → **Manage**
2. Search for and check the member → **Manage selected** → **Delete VMs and Data**
3. Watch the progress card until the member's row is complete, then select **Done**. A dashboard start where no selected member is still on the team shows **Not Started**

**Step 2: Remove access**
1. Remove the member from every Cursor team linked to the organization
2. With SCIM, unassigning the user in the IdP removes them from Cursor automatically, so do it only after Step 1
3. On Enterprise you can also take the member out of the group allowed by **Manage Group Access** (beside **Enable Grok Bot**) rather than dropping the whole group. On self-serve Teams, removing the member from the team is the only route

**Step 3: Revoke sessions and grants**
1. Revoke the user in your IdP, which ends their application sessions on the computer
2. Delete their Team Bots, or have them deleted (5.2)
3. Revoke connector grants at each source service

The dashboard path is transcribed from [Manage Grok Bot computers](https://docs.x.ai/grok-bot/computers).

#### Code Implementation

The pack is dry-run by default. Its sequence:

1. **Same-team proof:** before anything irreversible, in both modes, it proves the two keys point at the same team. The Team key's `GET /teams/model-access/configuration` returns the "Integer team ID implied by the API key"; where that route is not available, the pack compares the Team key's active members with the Organization API's members of `CURSOR_TEAM_ID`
2. **Leaver check:** it requires the leaver to be an active member on the Team key's team, so remove-member cannot fail after the delete
3. **Numeric id:** it resolves the member's numeric id with `GET /organizations/members?teamId=`
4. **Delete:** it starts `delete_vm_and_data` through `POST /organizations/teams/:teamId/grok-bot/operations` with a fresh `operationId`
5. **Poll:** it polls `GET /organizations/teams/:teamId/grok-bot/operations/:operationId` and checks that the polled operation is this member's `delete_vm_and_data` before trusting the member's item
6. **Remove:** only when that item succeeds does it call `POST /teams/remove-member` and print the IdP revocation reminder

The Organization API notes:

- Operations are turned on per team by the account team, and every route returns 403 until then
- Only an Organization key with `admin:*` works; other scopes return 401
- A queued operation returns 202, and 409 means another operation is running. Retrying with the same `operationId` returns the existing operation whatever its action: "Cursor doesn't compare the rest of the body on a retry, so generate a new UUID for every new operation". The pack resumes only through its own variable, `HTH_OFFBOARD_OPERATION_ID`, so an id exported for a 7.2 terminate can never stand in for a delete
- `userIds` are numeric ids from `GET /organizations/members?teamId=`, not the encoded `user_…` ids from `/teams/members`
- `delete_vm_and_data` is capped at 1,000 members and cannot be undone. `items[]` is null for operations of more than 1,000 members

**Remove-member:** `POST /teams/remove-member` ([Admin API](https://cursor.com/docs/account/teams/admin-api)) is Enterprise only and takes a Team key. It takes an encoded `user_…` id or an email, never both, and at least one paid member and one admin must remain.

**Audit evidence** comes from:

- `grok_bot_vm_bulk` (`bulk_permanent_delete`, with counts only and no user ids; "Its child operations emit no rows")
- `remove_user`
- `credentials_revoked` (`sessions` `revoked`, `retained` or `revoke_failed`)

Per-member proof of the delete comes from the operation's `items[]`.

{% include pack-code.html vendor="grok-bot" section="7.1" %}

#### Validation & Testing
1. The operation reports `succeeded` for the member, and `grok_bot_vm_bulk` shows `bulk_permanent_delete` with matching counts
2. `GET /teams/members` then shows `isRemoved` `true` on every linked team
3. The audit log shows `remove_user` and `credentials_revoked` with `sessions` `revoked`. `retained` means the member still belongs to another team in the organization, so sessions and repository grants stay valid
4. The member's next sign-in fails, and the IdP shows their sessions revoked

**Expected result:** A leaver's computer data is gone, their access is removed on every linked team, and their sessions are revoked.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **CIS Controls v8** | 5.3 | Disable Dormant Accounts |
| **CIS Controls v8** | 6.2 | Establish an Access Revoking Process |
| **NIST 800-53** | AC-2 | Account Management |
| **NIST 800-53** | PS-4 | Personnel Termination |
| **NIST 800-53** | MP-6 | Media Sanitization |
| **SOC 2** | CC6.2 | User registration and authorization |
| **SOC 2** | CC6.5 | Discontinuation of logical and physical protections over disposed assets |
| **ISO 27001:2022** | A.5.18 | Access rights |
| **ISO 27001:2022** | A.6.5 | Responsibilities after termination or change of employment |
| **ISO 27001:2022** | A.8.10 | Information deletion |
| **Product benchmark** | — | No product benchmark exists yet |

---

### 7.2 Prepare a Grok Bot Containment Runbook

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 17.4 |
| NIST 800-53 | IR-4, IR-8 |

#### Description
Write and rehearse a runbook for a hijacked Bot or a vendor-side incident, in five steps:

1. Disable Grok Bot or narrow **Manage Group Access**
   - Disabling blocks every member without deleting computers
   - An empty limited list is a 400, so use disable to block everyone
   - No page says whether disabling stops a Bot that is already working, so terminate as well (step 2)
2. Terminate affected computers to stop running Bots and in-flight routine runs ("Running work stops"). No page says that Terminate, the disable switch or removing access stops a scheduled routine from firing again
3. Have each affected routine's creator pause or delete it in their own chat (Bot → **View conversation details** → **Routines**; [Skills, routines, and automations](https://docs.x.ai/grok-bot/skills-routines-and-automations)). Revoke IdP sessions first (step 4) so that the legitimate member, not the attacker, does this cleanup
   - Routines are personal: "only they can see or change it" ([Team Bots](https://docs.x.ai/grok-bot/team-bots)), and on a Team Bot that includes teammates' routines, which the Bot's owner and managers cannot touch
   - Admins have no routine switch or API
   - For a hijacked Team Bot, an admin can delete it from **Manage Team Bots** (trash icon, type the exact name, **Delete**), which removes the Bot "for your whole team: teammates lose it, along with their chats and routines on it. This can't be undone."
   - Only its member can delete a personal Bot, and deleting a Bot removes its routines
4. Revoke IdP sessions, and revoke plugin authorization at each source service
5. Choose between Recreate, which keeps files and logins, and **Delete VMs and Data**, which is a true reset

Keep two keys ready:

- an Organization API key with `admin:*` for computer operations, which the account team must turn on per team
- a Team API key with `admin:*` for disable and access

#### Rationale
**Why This Matters:**
- Bots keep working while laptops are closed, and routines fire unattended
- Disabling Grok Bot blocks access, but no page says it stops work already running. Terminate is the documented way to stop running Bots ("Running work stops", Enterprise and organization admins only), and routines need their own step
- On self-serve Teams there is no switch and no Manage Bot Computers, so removing the member is the only documented way to end a member's access. Removing a Teams seat ends the Teams grant, but a personal SuperGrok or X Premium+ link on the same Cursor account is a separate grant
- Teams admins can still block connectors (2.1), set local execution to Never allow (2.4), turn off Cloud Agents (2.3) and revoke IdP sessions

**Attack Prevented:** Continued autonomous action during an active compromise

#### Prerequisites
- **Enterprise:** an organization admin, plus both API keys above
- A dedicated pilot team for rehearsal, because disable applies to the whole team

#### ClickOps Implementation

**Step 1: Stop access**
1. **Team-wide (Enterprise only):** **Cursor dashboard** → **Grok Bot** → **Enable Grok Bot** (switch) → Off
2. **Per cohort (Enterprise):** **Manage Group Access**, beside the switch

**Step 2: Stop running work (Enterprise, organization admins only)**
1. **Cursor dashboard** → **Grok Bot** → **Bot Computers** → **Manage Bot Computers** → **Manage**
2. Search and check members → **Manage selected** → **Terminate VMs**
3. On the confirmation screen select **Terminate VMs** → **Done**. The same menu also holds **Recreate VMs** and **Delete VMs and Data** ([Manage Grok Bot computers: Run an operation](https://docs.x.ai/grok-bot/computers))

**Step 3: Revoke, then stop routines**
1. Revoke IdP sessions and each plugin's authorization at its source service, so the legitimate member, not the attacker, does the routine cleanup
2. **Member (each routine's creator):** **View conversation details** → **Routines** → pause or delete each routine
3. **Admin, Team Bot only:** **Manage Team Bots** → **Delete** (irreversible; removes every teammate's routines on that Bot)
4. **Admin, verify:** pull `grok_bot_routine` audit rows. Action `disable` or `delete` on each affected `sand_agent_id` and `automation_id` confirms the cleanup; `create`, `update` or `enable` afterwards means re-arming. On Enterprise with Action Recording and OpenTelemetry Export (6.1), `cursor.grok_bot.routine_run` rows after containment show a routine still firing

#### Code Implementation

The pack is dry-run by default. It can disable Grok Bot, terminate computers or both, and it polls operations to completion.

- **Keys:** it reads the Team key and the Organization key from separate environment variables. When it is asked to disable and terminate together, it first proves both keys point at `CURSOR_TEAM_ID` (as in 7.1)
- **Resume:** it resumes only through its own `HTH_CONTAIN_OPERATION_ID`. It checks that the polled operation is a `terminate_vm` covering exactly the requested members before it reports "terminated", because a reused `operationId` returns whatever operation already holds it
- **Status:** its `status` check reports a 404 from the latest-operation route as confirmed only when the team is also linked to the organization, because that route returns 404 both before any operation has run and for an unlinked team

The calls:

- **Disable:** `POST /grok-bot/disable` with a Team key holding `admin:*`. It returns 204, and it "Returns **403** on Teams plans". A `read:*` key returns 401, and a 401 can also mean "Grok Bot Admin API not enabled for the team"
- **Narrow:** `PUT /grok-bot/access` returns 403 when group access is not available, and 400 for an empty limited list
- **Terminate:** `POST /organizations/teams/:teamId/grok-bot/operations` with action `terminate_vm`, up to 25,000 numeric `userIds`, and an `operationId`. It needs an Organization key with `admin:*`, turned on per team: until then the API answers "Bot fleet admin API access is not enabled for this team". It returns 409 with `runningOperationId` while another operation runs
- **Terminate preconditions:** every id "must belong to a current member of the team who has signed in to Cursor; if one doesn't, the request returns `400` and nothing starts", so with `HTH_CONTAIN_ALL=1` one unqualified member stops the whole terminate. List Organization Members exposes no signed-in field, so the pack cannot pre-filter. On a 400 it says nothing started and names the remedies (re-run, narrow with `HTH_CONTAIN_EMAILS`, or use **Terminate VMs** in the dashboard). Rehearse `HTH_CONTAIN_ALL` on the pilot team
- **Poll:** `GET .../operations/:operationId` or `.../operations/latest`. The latter returns 404 until an operation has run, and per-member items exist only for operations of 1,000 members or fewer

Detection:

- **Sigma rule:** it alerts on `sand_onboarding` with `new_completed` `false` (disable), on `grok_bot_vm_bulk` (`bulk_kill`, `bulk_recreate`, `bulk_permanent_delete`), and on `grok_bot_vm` with action `kill`
- **Event timing:** `grok_bot_vm_bulk` is emitted when a bulk operation completes, and its child operations emit no rows
- **Field paths:** streamed events nest fields under the event-type key (for example `sand_onboarding.new_completed`); Admin API pulls use `event_data`

{% include pack-code.html vendor="grok-bot" section="7.2" %}

#### Validation & Testing
1. Run a tabletop on a dedicated pilot team, because disable applies to the whole team
2. The pack's dry run lists the intended calls
3. A live terminate reports per-member results and emits `grok_bot_vm_bulk` `bulk_kill`
4. Before disabling, start a long task on a pilot Bot. Disable returns 204 and pilot members lose access; record whether the Bot that was mid-task stops before Terminate, since the docs do not say
5. Afterwards, the members pause or delete the pilot Bots' routines, and `grok_bot_routine` `disable` or `delete` rows confirm it

**Expected result:** A rehearsal on the pilot team proves each runbook step: access is blocked, running work stops, routines are paused or deleted by their creators, and sessions are revoked.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **CIS Controls v8** | 17.4 | Establish and Maintain an Incident Response Process |
| **NIST 800-53** | IR-4 | Incident Handling |
| **NIST 800-53** | IR-8 | Incident Response Plan |
| **SOC 2** | CC7.4 | Incident response |
| **ISO 27001:2022** | A.5.24 | Information security incident management planning and preparation |
| **ISO 27001:2022** | A.5.26 | Response to information security incidents |
| **Product benchmark** | — | No product benchmark exists yet |

---

### 7.3 Turn On Terminate Inactive Computers

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1 |
| NIST 800-53 | CM-2 |

#### Description
Turn on **Terminate Inactive Computers**, which terminates a member's computer after 30 days without use. It is Enterprise only, set by organization admins, and off by default.

**Why:** "A hibernated computer stays around until someone terminates it, even when the member has moved on or stopped using Grok Bot."

**Timing:** "Computers already past 30 days are included. There is no grace period." Termination lands in the days after the 30-day mark on a rolling schedule, and a computer that is awake is never terminated.

**Scope:** the setting applies to a member's computer if any of their Enterprise teams has it on.

**What a terminate does:** an automatic terminate works like a manual one. The durable disk stays, and the member's next message starts a fresh computer with their Bots, files and logins in place. Apps and packages members installed themselves are removed, and Team Setup runs again.

**What it is not:** this is idle-computer hygiene, not access removal or data deletion; for leavers, use 7.1.

#### Rationale
**Why This Matters:**
- Idle hibernated computers accumulate, and each one keeps self-installed software that drifts from the managed Team Setup baseline
- Termination clears that drift and re-applies Team Setup on next use
- It does not end access or sessions: the durable disk keeps browser sessions and logins, and "Terminating does not remove access" ([Manage Grok Bot computers](https://docs.x.ai/grok-bot/computers))

**Attack Prevented:** Drift and sprawl of idle computers carrying unmanaged software. It does not, on its own, prevent an attack on a member account; access and session risk is handled by 7.1 and IdP session revocation

#### ClickOps Implementation

**Step 1: Turn the setting on (Enterprise, organization admins)**
1. Navigate to: **Cursor dashboard** → **Grok Bot** → **Bot Computers** → **Terminate Inactive Computers**
2. Turn it on. A confirmation opens → **Turn On**

> **Doc conflict: placement and name.** The two docs disagree on placement. Confirm live.
>
> - **xAI:** its [Manage Grok Bot computers](https://docs.x.ai/grok-bot/computers) page puts the toggle "just above **Manage Bot Computers** in the same section", in a section it calls **Bot Computers**
> - **Cursor:** its [teams](https://cursor.com/docs/grok-bot/teams) page puts it "below it", meaning below the bulk control. Cursor uses **Grok Bot Computers** both as that bulk control's name and, on its [computers](https://cursor.com/docs/grok-bot/computers) page ("below **Grok Bot Computers** on the same dashboard page"), as the container for both features

**Automation:** ClickOps only — Cursor (the Grok Bot admin plane) exposes no write interface for this setting ([Admin API, Grok Bot](https://cursor.com/docs/account/teams/admin-api#grok-bot), 2026-10-08). It is not a field of `PATCH /grok-bot/capabilities`, and it is not an Organization API operation action ([Organization API, Grok Bot computers](https://cursor.com/docs/account/organizations/organization-admin-api#grok-bot-computers), 2026-10-08).

- **Not readable either:** `GET /grok-bot/capabilities` does not return it
- **Manual equivalent:** the Organization API's `terminate_vm` (7.2) is a scriptable manual equivalent of a single cleanup run, not the setting
- **No detection:** no documented audit event distinguishes automatic termination, and the toggle's `team_settings` `setting_name` is undocumented, so no detection is authored for it

#### Validation & Testing
1. The **Terminate Inactive Computers** toggle is on in **Bot Computers**
2. A pilot member whose computer has slept for more than 30 days finds, in the days after the mark, that their next message starts a fresh computer, with self-installed packages gone and Team Setup re-applied

**Expected result:** No member computer stays idle beyond roughly 30 days with unmanaged software on it.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **CIS Controls v8** | 4.1 | Establish and Maintain a Secure Configuration Process |
| **NIST 800-53** | CM-2 | Baseline Configuration |
| **SOC 2** | CC8.1 | Change management |
| **ISO 27001:2022** | A.8.9 | Configuration management |
| **Product benchmark** | — | No product benchmark exists yet |

---

## 8. Known Gaps and Member Guidance

This section is reference material, not a set of controls, and it adds no cheat-sheet rows. It records the risks the vendor documents but gives admins no control over, the documentation conflicts this guide could not resolve without a live tenant, and the member-level settings that matter.

### 8.1 Surfaces With No Admin Control

| Surface | What the docs say | Nearest lever |
|---------|-------------------|---------------|
| **Tagging @bot on X** | Tagging `@bot` in a post hands it to the member's main Bot, and X tells the member that "tagged requests start work automatically". It needs a Grok account with X connected, Grok Bot access on that account, and "At least one Bot of your own"; "Bots that someone shares with you can't take tagged requests", so a teammate's Team Bot is not reachable this way. It is "not yet available for accounts based in Australia, the United Kingdom, the European Union, Iceland, Liechtenstein, or Norway". No admin setting disables it ([Tag @bot on X](https://docs.x.ai/grok-bot/tag-on-x)) | Network Controls (3.1), Enforce Auto-review (4.1), Action Recording (6.1) |
| **Routines and Slack or webhook triggers** | On a Team Bot, routines are personal: a routine "runs as" the member who set it up, "and only they can see or change it" ([Team Bots](https://docs.x.ai/grok-bot/team-bots)). A Bot template carries its routines, and "A public link can be opened by anyone who has it and shows the Bot's shared configuration, including its identity, description, skills, and routines" ([Create and manage Bots](https://docs.x.ai/grok-bot/bots)). There is no allowlist, disable switch or API. A Bot can own up to 50 routines, and schedules must be at least five minutes apart ([Skills, routines, and automations](https://docs.x.ai/grok-bot/skills-routines-and-automations)). Routines run "while your laptop is closed" ([Cursor help: Routines](https://cursor.com/help/grok-bot/routines)) | Public template sharing off (5.1), `grok_bot_routine` audit events (6.2), `routine_run` over OpenTelemetry (6.1), and Auto Review on automation writes (4.1), whose approvals go to the member |
| **Team Bot creation and publishing** | No documented admin control disables it (as of 2026-10-09), and there is no Team Bot API | Manage Team Bots (5.2); Manage Group Access limits it indirectly on Enterprise (1.1) |
| **Bot memory and Team Bot team memory** | No admin view or purge. Auto Review does not review memory writes | Team Bot governance (5.2), offboarding (7.1) |
| **Spend** | "A separate Grok Bot spend cap is not available today." Account-level on-demand controls apply | [cursor 3.3](/guides/cursor/#33-monitor-api-key-usage-and-costs) |
| **Team Bot ownership transfer** | Not documented, and nothing is documented about a Team Bot after its owner leaves the team | Owner deletion before departure, or admin deletion in Manage Team Bots (7.1) |
| **Model restriction** | docs.x.ai says the team model allowlist "is honored by default" but that "enforcement is not guaranteed" ([Grok Bot security](https://docs.x.ai/grok-bot/security)). cursor.com says "The team model allowlist does not govern Grok Bot" ([Cursor: Grok Bot security](https://cursor.com/docs/grok-bot/security)), and "Grok Bot is not governed by your team's Cursor model allowlist or blocklist" ([Cursor help: models](https://cursor.com/help/grok-bot/models)) | None. This guide writes no model-restriction control; review the sub-processor list with your account team |

### 8.2 Vendor-Admitted Design Gaps

The vendor documents these as absences. They are design gaps to weigh in a risk assessment, not settings to configure ([Grok Bot security](https://docs.x.ai/grok-bot/security), [Grok Bot security FAQ](https://docs.x.ai/grok-bot/security-faq)).

- **No DLP hooks:** "Dedicated data loss prevention hooks are not available."
- **No customer telemetry or EDR feed:** Grok Bot "does not ship a built-in customer-facing telemetry or EDR feed". Team Setup (3.3) is the path to install your own
- **Shared egress:** static egress IPs are shared across all Grok Bot customers, and dedicated per-customer IPs are not available
- **Residency:** computers run in the United States, but outside Cursor's US-only data residency program by default
- **Retention and restore:** there is no per-organization retention policy and no customer-managed point-in-time restore of an individual computer
- **Hosting:** there is no on-premises, in-perimeter or bring-your-own-image deployment
- **Identity:** Bots act as the signed-in member rather than as distinct agent principals, and all of a user's Bots share one computer. "Do not use separate Bots as a security boundary." ([Approvals, security, and privacy](https://docs.x.ai/grok-bot/approvals-security-and-privacy))

### 8.3 Changelog-Only Capabilities

These appear in the [Grok Bot changelog](https://x.ai/changelog/bot) and have no admin control (see Appendix B on how the changelog was read).

- **V0.30.0 and V0.33.0:** Link purchases on approval, and Pay with Link
- **V0.53.0:** 1Password Auto fill
- **V0.64.0:** a member-level **Disable drafts for this Bot**, which lets that Bot send email and Slack messages directly. Keep drafts on (8.7)
- **V0.37.0:** "Allow once works even when Execution on this computer is set to Never allow". Test it live against the team ceiling in 2.4

### 8.4 Access Paths Outside Cursor-Team Governance

- **Self-serve Grok Business seats (1.3):** seat removal is the only documented lever. It is undocumented which Cursor team such a user lands in, and whether domain-verified SSO or the MDM allowed-team-ID policy applies to a Sign in with Grok session
- **Personal SuperGrok, SuperGrok Plus, SuperGrok Heavy and X Premium+ links:** no documented admin control, and such a link "can't be unlinked or moved" to a different Cursor account once created ([SuperGrok and Grok Bot](https://cursor.com/help/grok-bot/supergrok))
- **Grok Enterprise:** access goes through the account manager, with no documented controls
- **Sign-in domains:** Cursor sign-in is moving to accounts.x.ai and accounts.spacex.ai, and the fallback is retired on October 30 ([Sign-in domains](https://cursor.com/help/troubleshooting/sign-in-domains); the page gives no year, and was read on 2026-10-09, so this is presumably October 30, 2026). Update proxy allowlists ([cursor 9.2](/guides/cursor/#92-configure-network-allowlisting))

### 8.5 Audit Coverage Holes

No Grok-Bot-specific audit event or documented `setting_name` covers any of these:

- team network-policy changes
- the Enforce Auto-review toggle
- the `PATCH /grok-bot/capabilities` fields
- Team Secrets
- Terminate Inactive Computers
- Manage Team Bots assignment
- Team Bot managers, secrets, plugins and files (changelog V0.57.0 claims plugin activity is audited; see 8.6)
- Team Bot Slack apps

The generic `team_settings` event's `setting_name` list is explicitly non-exhaustive, and it fires for team-wide changes "including changes made through the Admin API", so some of these may land there. The 6.2 pack lists unrecognized `setting_name` values for review.

Whether `team_rule` covers Grok-Bot-scoped rules is inferred rather than documented. Audit streaming is set up by contacting hi@cursor.com ([Compliance and monitoring](https://cursor.com/docs/enterprise/compliance-and-monitoring)).

**Sigma rules:** Cursor's audit stream and OpenTelemetry export have no upstream Sigma taxonomy. This guide's Sigma rules therefore declare a custom logsource and field mapping in each pack header.

- Field paths differ between streamed audit events, which nest fields under a key named after the event type, and Admin API pulls, which use `event_data`
- The rules match only documented `event_type`, action and attribute values
- `grok_bot_routine` `trigger_type` values and `grok_bot_group_settings` `setting_name` values are not enumerated, so no rule filters on them

### 8.6 Documentation Conflicts to Resolve Live

| Topic | Conflict | This guide's position |
|-------|----------|-----------------------|
| **Admin API reach on Teams** | [cursor.com/docs/api](https://cursor.com/docs/api) lists the Admin API as "Enterprise teams". The [Grok Bot section](https://cursor.com/docs/account/teams/admin-api#grok-bot) says `/access`, `/network` and `/auto-review` reads work "on every plan", and documents 403 on Teams for disable and network writes. `GET /grok-bot/capabilities` is not in that every-plan read list, and no Teams behavior is documented for enable | Writes are confirmed for Enterprise only. Every pack treats 401 and 403 as "not available to this team/plan" |
| **Enterprise enablement** | The [plans page](https://cursor.com/help/grok-bot/plans), which Cursor calls canonical, says "Consult your account executive to enable Grok Bot access for your team". The [teams page](https://cursor.com/docs/grok-bot/teams) and the docs.x.ai mirror say "On the Enterprise plan, an admin turns it on from Grok Bot in the Cursor dashboard". The Admin API's `POST /grok-bot/enable` says "The first enable on an eligible Enterprise team starts the trial". No page defines eligibility, the trial's length, or what follows it | Engage the account executive before rollout. Confirm live whether the dashboard switch is available to the team and whether the first enable starts a trial, and record that first enable as an approved change (1.1) |
| **Entra policy precedence** | xAI's "Add a higher-priority policy" and "laptop sign-ins keep your existing requirements" versus Microsoft's "all applicable policies must be satisfied" | Follow Microsoft. Treat the step 8 exclusions as the actual exception, record them, and pick the narrowest form (1.2, Step 2a) |
| **Team Bot editors** | [xAI Team Bots](https://docs.x.ai/grok-bot/team-bots): "Only the owner and the Bot's managers can change this setup", and "A manager can change the Bot's setup, like its profile, skills, plugins, secrets, and Slack app". [Cursor help: Team Bots](https://cursor.com/help/grok-bot/team-bots): "Only the owner can change a Team Bot", with no manager role | Treat managers as real, since xAI documents **Add manager** under the Bot's details → **Setup** → **Managers**. Confirm live that the Managers section exists (5.2, 7.1) |
| **Team Bot after owner departure** | The Team Bots page covers owner, manager and admin rights, but not what happens to a Team Bot, its secrets, its Slack app or its owner-billed Slack usage when the owner leaves the team | Delete the owner's Team Bots before removing the member (7.1); confirm the post-removal behavior live |
| **Plugin audit coverage** | Changelog V0.57.0 says "Audit Logs record more Grok Bot activity, including … plugins". The [event table](https://cursor.com/docs/enterprise/compliance-and-monitoring) has no Grok Bot plugin event, and the generic `mcp_authentication` and `mcp_server_config` events are not documented to cover a Team Bot's plugin changes | Current docs win: Team Bot plugin changes are treated as unaudited (5.2, 8.5). Confirm live which `event_type`, if any, a Team Bot plugin change emits |
| **Per-team enablement** | The Admin API can return 401 "Grok Bot Admin API not enabled for the team", and Organization API computer operations return 403 until the account team turns them on. The Organization API uses numeric user ids; the team API uses encoded `user_…` ids | Packs handle both id types and both refusals |
| **Group type for access** | Manage Group Access links to Members > Groups; `PUT /grok-bot/access` takes billing groups | Confirm the picker live (1.1) |
| **Network allowlist size** | Security page: "no cap on the number of entries". API: "Up to 500 destinations" | The pack enforces 500 (3.1) |
| **Template sharing values** | The API lists `all`, `team_only`, `none` and `null`, but does not define `none` or map the dashboard's Off | The pack enforces `team_only` (5.1) |
| **Auto-review rule semantics** | The API's `allow`/`block` map to the UI's Allow automatically/Ask first only by inference. Empty lists keep stored rules only for teams that cannot set rules | Rule authoring stays in the dashboard. The pack re-sends stored rules (4.1) |
| **Action Recording and the Audit Log** | Changelog V0.30.0 says recordings go to the audit log; the current docs say they do not | Current docs win (6.1) |
| **Launch plan list** | The 2026-08-11 launch post already lists plans that the 2026-08-26 post says were added that day | Cursor's plans page is canonical (Overview) |
| **UI labels** | Bot Computers → Manage Bot Computers (xAI) vs Grok Bot Computers (Cursor); Terminate Inactive Computers "just above" vs "below" (7.3); Route traffic through this computer vs Route egress through this desktop, with different locked messages (3.2); Settings → Computer → Computers (xAI) vs Settings > Computer > Execution on this computer (Cursor) for the member's local-execution setting (2.4); Settings → General → Auto-review vs the General > Bot section of Cursor's settings page, and "Custom Rules" (4.1); Team Marketplace vs Teams Marketplace vs Connect Apps (2.1); Team Bots → Manage Team Bots (xAI) vs Manage Team Bots → Manage (Cursor), with Cursor help listing no **None** option (5.2); "Allow Cloud Agents" on a group tab is described only in prose (2.3); no documented labels for Team Rules (4.2) or public template sharing (5.1); Members & Groups vs Members > Groups (4.3) | Transcribe each live before rollout |
| **Terraform** | cursor/cursor 0.8.0 was published on 2026-10-08, the day of this census, and has no Grok Bot resources ([registry](https://registry.terraform.io/v1/providers/cursor/cursor)) | Recheck at publish; any new resource changes the automation verdicts |

### 8.7 Member Guidance

These are member-level settings, not admin controls. Put them in your acceptable-use guidance and onboarding. The vendor's own member baseline is in [Grok Bot for teams and enterprises](https://docs.x.ai/grok-bot/teams-and-enterprises#recommended-configuration).

- **Never paste credentials into chat.** The masked secret request is the supported path. On a Team Bot, every secret is usable in any teammate's conversation (5.2)
- **Prefer Allow once over Always allow** for actions that touch accounts, money or shared resources
- **Size the shared browser to the task.** Every Bot on the account shares one computer's cookies, files and command-line credentials ([Computer and apps](https://docs.x.ai/grok-bot/computer-and-apps)). Sign the Bot's browser out of accounts it no longer needs, and use scoped service accounts where the source system supports them
- **Keep personal Auto-review rules.** They are stored per desktop and synced to that desktop's computer, under **Settings → General → Auto-review**
- **Keep email and Slack drafts on.** Do not use **Disable drafts for this Bot** (changelog V0.64.0)
- **Clear remembered connector consent** for Team Bots: **Settings → General → Team Bots** → **Clear** ([Team Bots](https://docs.x.ai/grok-bot/team-bots))
- **Use hardware security key passthrough** where available: **Settings → General → Security Key** → **Use hardware security keys**. It is on by default on macOS and Windows, is not yet supported on Linux, and asks for approval on every use
- **Start new Bots on read-only tasks and drafts**, and review installed plugins and active routines regularly. Pause a routine when its source system changes

---

## 9. Compliance Quick Reference

No product benchmark exists yet for Grok Bot. The mappings below are control-family mappings, not benchmark equivalents.

- **CIS:** the research pass found no CIS Benchmark for xAI, Grok, Grok Bot or Cursor. CIS's only AI benchmark, MCP Server (1.0.0), is partially relevant to connectors but is not product coverage. The cisecurity.org catalog is a JavaScript shell to fetchers, so re-check it in a real browser before relying on this
- **DISA:** the public STIG Document Library ([cyber.mil/stigs/downloads](https://www.cyber.mil/stigs/downloads); the page is rendered by JavaScript and was checked in a real browser on 2026-10-09) lists no xAI, Grok or Cursor STIG. Searches for Grok, xAI and Cursor returned no results, while control searches for Kubernetes and Cisco returned 4 and 13. Documents limited to DoD CAC holders were not checked
- **CISA SCuBA:** it has no xAI or Grok baseline; its Entra ID baseline applies only to 1.2, as a labeled compatibility exception

### SOC 2 Trust Services Criteria Mapping

| Control ID | Grok Bot Control | Guide Section |
|-----------|------------------|---------------|
| CC2.2 | Required Team Rules | [4.2](#42-set-required-team-rules-for-grok-bot) |
| CC6.1 | Access scoping, IdP exception, connectors, Google approval, Cloud Agents, local execution, Team Setup, Auto-review, Team Rules, template sharing, Team Bots | [1.1](#11-limit-grok-bot-to-approved-groups), [1.2](#12-scope-the-idp-sign-in-exception-for-the-bots-computer-browser), [2.1](#21-restrict-the-connectors-every-bot-inherits), [2.2](#22-gate-google-plugins-by-approving-the-grok-oauth-app), [2.3](#23-disable-cloud-agent-delegation-unless-needed), [2.4](#24-set-the-team-execution-on-local-computer-ceiling-to-never-allow), [3.3](#33-govern-team-setup-scripts-and-keep-credentials-in-team-secrets), [4.1](#41-enforce-auto-review-with-team-ask-first-rules), [4.2](#42-set-required-team-rules-for-grok-bot), [5.1](#51-keep-public-template-sharing-off), [5.2](#52-govern-team-bots-their-shared-credentials-and-their-slack-apps) |
| CC6.2 | Access scoping, Grok Business seats, offboarding | [1.1](#11-limit-grok-bot-to-approved-groups), [1.3](#13-treat-grok-business-seats-as-grok-bot-provisioning), [7.1](#71-offboard-completely-delete-computer-data-remove-access-revoke-sessions) |
| CC6.3 | Grok Business seats, Team Bots | [1.3](#13-treat-grok-business-seats-as-grok-bot-provisioning), [5.2](#52-govern-team-bots-their-shared-credentials-and-their-slack-apps) |
| CC6.5 | Offboarding data deletion | [7.1](#71-offboard-completely-delete-computer-data-remove-access-revoke-sessions) |
| CC6.6 | Network Controls, Allow Local Egress | [3.1](#31-enforce-a-destination-allowlist-with-network-controls), [3.2](#32-turn-off-allow-local-egress) |
| CC6.8 | Local execution ceiling | [2.4](#24-set-the-team-execution-on-local-computer-ceiling-to-never-allow) |
| CC7.2 | Group override audit, Action Recording, control-plane audit | [4.3](#43-audit-group-grok-bot-tabs-for-widening-overrides), [6.1](#61-turn-on-action-recording-and-export-it-over-opentelemetry), [6.2](#62-monitor-grok-bot-control-plane-audit-events) |
| CC7.3 | Action Recording | [6.1](#61-turn-on-action-recording-and-export-it-over-opentelemetry) |
| CC7.4 | Containment runbook | [7.2](#72-prepare-a-grok-bot-containment-runbook) |
| CC8.1 | Team Setup change control, Auto-review, group overrides, inactive computers | [3.3](#33-govern-team-setup-scripts-and-keep-credentials-in-team-secrets), [4.1](#41-enforce-auto-review-with-team-ask-first-rules), [4.3](#43-audit-group-grok-bot-tabs-for-widening-overrides), [7.3](#73-turn-on-terminate-inactive-computers) |
| CC9.2 | Connector policy | [2.1](#21-restrict-the-connectors-every-bot-inherits) |
| C1.1 | Template sharing | [5.1](#51-keep-public-template-sharing-off) |

### NIST 800-53 Rev 5 Mapping

| Control | Grok Bot Control | Guide Section |
|---------|------------------|---------------|
| AC-2 | Access scoping, Grok Business seats, offboarding | [1.1](#11-limit-grok-bot-to-approved-groups), [1.3](#13-treat-grok-business-seats-as-grok-bot-provisioning), [7.1](#71-offboard-completely-delete-computer-data-remove-access-revoke-sessions) |
| AC-3 | Access scoping, Google approval, Auto-review, template sharing | [1.1](#11-limit-grok-bot-to-approved-groups), [2.2](#22-gate-google-plugins-by-approving-the-grok-oauth-app), [4.1](#41-enforce-auto-review-with-team-ask-first-rules), [5.1](#51-keep-public-template-sharing-off) |
| AC-4 | Network Controls, Allow Local Egress | [3.1](#31-enforce-a-destination-allowlist-with-network-controls), [3.2](#32-turn-off-allow-local-egress) |
| AC-6 | Connectors, Google approval, Cloud Agents, local execution, Auto-review, Team Rules, Team Bots | [2.1](#21-restrict-the-connectors-every-bot-inherits), [2.2](#22-gate-google-plugins-by-approving-the-grok-oauth-app), [2.3](#23-disable-cloud-agent-delegation-unless-needed), [2.4](#24-set-the-team-execution-on-local-computer-ceiling-to-never-allow), [4.1](#41-enforce-auto-review-with-team-ask-first-rules), [4.2](#42-set-required-team-rules-for-grok-bot), [5.2](#52-govern-team-bots-their-shared-credentials-and-their-slack-apps) |
| AC-17 | IdP exception, local execution, Allow Local Egress | [1.2](#12-scope-the-idp-sign-in-exception-for-the-bots-computer-browser), [2.4](#24-set-the-team-execution-on-local-computer-ceiling-to-never-allow), [3.2](#32-turn-off-allow-local-egress) |
| AC-20 | IdP exception, Grok Business seats | [1.2](#12-scope-the-idp-sign-in-exception-for-the-bots-computer-browser), [1.3](#13-treat-grok-business-seats-as-grok-bot-provisioning) |
| AC-21 | Template sharing, Team Bots | [5.1](#51-keep-public-template-sharing-off), [5.2](#52-govern-team-bots-their-shared-credentials-and-their-slack-apps) |
| AU-2 | Action Recording, control-plane audit | [6.1](#61-turn-on-action-recording-and-export-it-over-opentelemetry), [6.2](#62-monitor-grok-bot-control-plane-audit-events) |
| AU-3 | Action Recording | [6.1](#61-turn-on-action-recording-and-export-it-over-opentelemetry) |
| AU-6 | Group override audit, control-plane audit | [4.3](#43-audit-group-grok-bot-tabs-for-widening-overrides), [6.2](#62-monitor-grok-bot-control-plane-audit-events) |
| AU-12 | Action Recording | [6.1](#61-turn-on-action-recording-and-export-it-over-opentelemetry) |
| CM-2 | Inactive computers | [7.3](#73-turn-on-terminate-inactive-computers) |
| CM-3 | Team Setup, group overrides | [3.3](#33-govern-team-setup-scripts-and-keep-credentials-in-team-secrets), [4.3](#43-audit-group-grok-bot-tabs-for-widening-overrides) |
| CM-5 | Team Setup | [3.3](#33-govern-team-setup-scripts-and-keep-credentials-in-team-secrets) |
| CM-6 | Group overrides | [4.3](#43-audit-group-grok-bot-tabs-for-widening-overrides) |
| CM-7 | Connectors, Google approval, Cloud Agents, local execution | [2.1](#21-restrict-the-connectors-every-bot-inherits), [2.2](#22-gate-google-plugins-by-approving-the-grok-oauth-app), [2.3](#23-disable-cloud-agent-delegation-unless-needed), [2.4](#24-set-the-team-execution-on-local-computer-ceiling-to-never-allow) |
| IA-2 | IdP exception | [1.2](#12-scope-the-idp-sign-in-exception-for-the-bots-computer-browser) |
| IA-5 | Team Bots | [5.2](#52-govern-team-bots-their-shared-credentials-and-their-slack-apps) |
| IA-5(7) | Team Secrets | [3.3](#33-govern-team-setup-scripts-and-keep-credentials-in-team-secrets) |
| IR-4 | Containment runbook | [7.2](#72-prepare-a-grok-bot-containment-runbook) |
| IR-8 | Containment runbook | [7.2](#72-prepare-a-grok-bot-containment-runbook) |
| MP-6 | Offboarding data deletion | [7.1](#71-offboard-completely-delete-computer-data-remove-access-revoke-sessions) |
| PL-4 | Team Rules | [4.2](#42-set-required-team-rules-for-grok-bot) |
| PS-4 | Offboarding | [7.1](#71-offboard-completely-delete-computer-data-remove-access-revoke-sessions) |
| SA-9 | Connectors | [2.1](#21-restrict-the-connectors-every-bot-inherits) |
| SC-7 | Network Controls, Allow Local Egress | [3.1](#31-enforce-a-destination-allowlist-with-network-controls), [3.2](#32-turn-off-allow-local-egress) |
| SC-7(5) | Network Controls | [3.1](#31-enforce-a-destination-allowlist-with-network-controls) |
| SI-4 | Team Setup EDR, Auto-review, Action Recording, control-plane audit | [3.3](#33-govern-team-setup-scripts-and-keep-credentials-in-team-secrets), [4.1](#41-enforce-auto-review-with-team-ask-first-rules), [6.1](#61-turn-on-action-recording-and-export-it-over-opentelemetry), [6.2](#62-monitor-grok-bot-control-plane-audit-events) |

### ISO 27001:2022 Mapping

| Control | Grok Bot Control | Guide Section |
|---------|------------------|---------------|
| A.5.10 | Team Rules | [4.2](#42-set-required-team-rules-for-grok-bot) |
| A.5.14 | Template sharing | [5.1](#51-keep-public-template-sharing-off) |
| A.5.15 | Access scoping, Google approval, Auto-review, Team Bots | [1.1](#11-limit-grok-bot-to-approved-groups), [2.2](#22-gate-google-plugins-by-approving-the-grok-oauth-app), [4.1](#41-enforce-auto-review-with-team-ask-first-rules), [5.2](#52-govern-team-bots-their-shared-credentials-and-their-slack-apps) |
| A.5.17 | IdP exception, Team Secrets, Team Bots | [1.2](#12-scope-the-idp-sign-in-exception-for-the-bots-computer-browser), [3.3](#33-govern-team-setup-scripts-and-keep-credentials-in-team-secrets), [5.2](#52-govern-team-bots-their-shared-credentials-and-their-slack-apps) |
| A.5.18 | Access scoping, Grok Business seats, offboarding | [1.1](#11-limit-grok-bot-to-approved-groups), [1.3](#13-treat-grok-business-seats-as-grok-bot-provisioning), [7.1](#71-offboard-completely-delete-computer-data-remove-access-revoke-sessions) |
| A.5.19 | Connectors | [2.1](#21-restrict-the-connectors-every-bot-inherits) |
| A.5.23 | Grok Business seats, connectors, Google approval | [1.3](#13-treat-grok-business-seats-as-grok-bot-provisioning), [2.1](#21-restrict-the-connectors-every-bot-inherits), [2.2](#22-gate-google-plugins-by-approving-the-grok-oauth-app) |
| A.5.24 | Containment runbook | [7.2](#72-prepare-a-grok-bot-containment-runbook) |
| A.5.26 | Containment runbook | [7.2](#72-prepare-a-grok-bot-containment-runbook) |
| A.6.5 | Offboarding | [7.1](#71-offboard-completely-delete-computer-data-remove-access-revoke-sessions) |
| A.8.1 | Local execution | [2.4](#24-set-the-team-execution-on-local-computer-ceiling-to-never-allow) |
| A.8.5 | IdP exception | [1.2](#12-scope-the-idp-sign-in-exception-for-the-bots-computer-browser) |
| A.8.9 | Cloud Agents, local execution, Team Setup, Auto-review, group overrides, inactive computers | [2.3](#23-disable-cloud-agent-delegation-unless-needed), [2.4](#24-set-the-team-execution-on-local-computer-ceiling-to-never-allow), [3.3](#33-govern-team-setup-scripts-and-keep-credentials-in-team-secrets), [4.1](#41-enforce-auto-review-with-team-ask-first-rules), [4.3](#43-audit-group-grok-bot-tabs-for-widening-overrides), [7.3](#73-turn-on-terminate-inactive-computers) |
| A.8.10 | Offboarding data deletion | [7.1](#71-offboard-completely-delete-computer-data-remove-access-revoke-sessions) |
| A.8.15 | Action Recording, control-plane audit | [6.1](#61-turn-on-action-recording-and-export-it-over-opentelemetry), [6.2](#62-monitor-grok-bot-control-plane-audit-events) |
| A.8.16 | Action Recording, control-plane audit | [6.1](#61-turn-on-action-recording-and-export-it-over-opentelemetry), [6.2](#62-monitor-grok-bot-control-plane-audit-events) |
| A.8.20 | Network Controls, Allow Local Egress | [3.1](#31-enforce-a-destination-allowlist-with-network-controls), [3.2](#32-turn-off-allow-local-egress) |
| A.8.22 | Network Controls, Allow Local Egress | [3.1](#31-enforce-a-destination-allowlist-with-network-controls), [3.2](#32-turn-off-allow-local-egress) |
| A.8.32 | Team Setup change control | [3.3](#33-govern-team-setup-scripts-and-keep-credentials-in-team-secrets) |

### CIS Controls v8 Mapping

| Safeguard | Grok Bot Control | Guide Section |
|-----------|------------------|---------------|
| 2.5 | Connectors, Google approval | [2.1](#21-restrict-the-connectors-every-bot-inherits), [2.2](#22-gate-google-plugins-by-approving-the-grok-oauth-app) |
| 2.7 | Team Setup scripts | [3.3](#33-govern-team-setup-scripts-and-keep-credentials-in-team-secrets) |
| 3.3 | Template sharing, Team Bots | [5.1](#51-keep-public-template-sharing-off), [5.2](#52-govern-team-bots-their-shared-credentials-and-their-slack-apps) |
| 4.1 | Local execution, Team Setup, Auto-review, Team Rules, group overrides, inactive computers | [2.4](#24-set-the-team-execution-on-local-computer-ceiling-to-never-allow), [3.3](#33-govern-team-setup-scripts-and-keep-credentials-in-team-secrets), [4.1](#41-enforce-auto-review-with-team-ask-first-rules), [4.2](#42-set-required-team-rules-for-grok-bot), [4.3](#43-audit-group-grok-bot-tabs-for-widening-overrides), [7.3](#73-turn-on-terminate-inactive-computers) |
| 4.8 | Connectors, Cloud Agents, local execution | [2.1](#21-restrict-the-connectors-every-bot-inherits), [2.3](#23-disable-cloud-agent-delegation-unless-needed), [2.4](#24-set-the-team-execution-on-local-computer-ceiling-to-never-allow) |
| 5.3 | Offboarding | [7.1](#71-offboard-completely-delete-computer-data-remove-access-revoke-sessions) |
| 6.1 | Access scoping, Grok Business seats, Google approval | [1.1](#11-limit-grok-bot-to-approved-groups), [1.3](#13-treat-grok-business-seats-as-grok-bot-provisioning), [2.2](#22-gate-google-plugins-by-approving-the-grok-oauth-app) |
| 6.2 | Grok Business seats, offboarding | [1.3](#13-treat-grok-business-seats-as-grok-bot-provisioning), [7.1](#71-offboard-completely-delete-computer-data-remove-access-revoke-sessions) |
| 6.3 | IdP exception | [1.2](#12-scope-the-idp-sign-in-exception-for-the-bots-computer-browser) |
| 6.7 | Access scoping | [1.1](#11-limit-grok-bot-to-approved-groups) |
| 6.8 | Team Bots | [5.2](#52-govern-team-bots-their-shared-credentials-and-their-slack-apps) |
| 8.2 | Action Recording, control-plane audit | [6.1](#61-turn-on-action-recording-and-export-it-over-opentelemetry), [6.2](#62-monitor-grok-bot-control-plane-audit-events) |
| 8.5 | Action Recording | [6.1](#61-turn-on-action-recording-and-export-it-over-opentelemetry) |
| 8.9 | Action Recording, control-plane audit | [6.1](#61-turn-on-action-recording-and-export-it-over-opentelemetry), [6.2](#62-monitor-grok-bot-control-plane-audit-events) |
| 8.11 | Group override audit, control-plane audit | [4.3](#43-audit-group-grok-bot-tabs-for-widening-overrides), [6.2](#62-monitor-grok-bot-control-plane-audit-events) |
| 9.3 | Network Controls | [3.1](#31-enforce-a-destination-allowlist-with-network-controls) |
| 10.1 | Team Setup EDR | [3.3](#33-govern-team-setup-scripts-and-keep-credentials-in-team-secrets) |
| 12.2 | Allow Local Egress | [3.2](#32-turn-off-allow-local-egress) |
| 13.4 | Network Controls, Allow Local Egress | [3.1](#31-enforce-a-destination-allowlist-with-network-controls), [3.2](#32-turn-off-allow-local-egress) |
| 17.4 | Containment runbook | [7.2](#72-prepare-a-grok-bot-containment-runbook) |

### OWASP Top 10 for Agentic Applications (2026) and LLM Top 10 (2025)

| Risk | Grok Bot Control | Guide Section |
|------|------------------|---------------|
| ASI01 Agent Goal Hijack | Network Controls, Auto-review, Team Bots | [3.1](#31-enforce-a-destination-allowlist-with-network-controls), [4.1](#41-enforce-auto-review-with-team-ask-first-rules), [5.2](#52-govern-team-bots-their-shared-credentials-and-their-slack-apps) |
| ASI02 Tool Misuse | Connectors, Cloud Agents, local execution | [2.1](#21-restrict-the-connectors-every-bot-inherits), [2.3](#23-disable-cloud-agent-delegation-unless-needed), [2.4](#24-set-the-team-execution-on-local-computer-ceiling-to-never-allow) |
| ASI03 Identity & Privilege Abuse | Access scoping | [1.1](#11-limit-grok-bot-to-approved-groups) |
| ASI05 Unexpected Code Execution | Local execution | [2.4](#24-set-the-team-execution-on-local-computer-ceiling-to-never-allow) |
| ASI06 Memory & Context Poisoning | Team Bots | [5.2](#52-govern-team-bots-their-shared-credentials-and-their-slack-apps) |
| ASI07 Insecure Inter-Agent Communication | Team Bots | [5.2](#52-govern-team-bots-their-shared-credentials-and-their-slack-apps) |
| ASI09 Human-Agent Trust Exploitation | Auto-review | [4.1](#41-enforce-auto-review-with-team-ask-first-rules) |
| ASI10 Rogue Agents | Action Recording | [6.1](#61-turn-on-action-recording-and-export-it-over-opentelemetry) |
| LLM06:2025 Excessive Agency | Auto-review | [4.1](#41-enforce-auto-review-with-team-ask-first-rules) |

OWASP risk names are taken from OWASP's [Agentic Top 10 launch post](https://genai.owasp.org/2025/12/09/owasp-top-10-for-agentic-applications-the-benchmark-for-agentic-security-in-the-age-of-autonomous-ai/) and [LLM06:2025 Excessive Agency](https://genai.owasp.org/llmrisk/llm062025-excessive-agency/). They are framework mappings, not configuration requirements.

### CISA SCuBA

| Policy | Relationship | Guide Section |
|--------|--------------|---------------|
| MS.AAD.3.1v1 | Labeled compatibility exception: the vendor's Bot-browser rule relaxes phishing-resistant MFA | [1.2](#12-scope-the-idp-sign-in-exception-for-the-bots-computer-browser) |
| MS.AAD.3.7v1 | Labeled compatibility exception: the vendor's Bot-browser rule admits an unmanaged device | [1.2](#12-scope-the-idp-sign-in-exception-for-the-bots-computer-browser) |

---

## Appendix A: Edition/Plan Availability

Self-serve Cursor Teams cannot turn Grok Bot off. It lacks Network Controls, Enforce Auto-review and Auto-review rules, Team Setup and Team Secrets, Allow Local Egress, Action Recording, audit logs, OpenTelemetry Export, SCIM, group Grok Bot tabs and Manage Bot Computers, so it also has no data-deletion path.

A Teams admin can apply:

- 1.1 through team membership and IdP assignment
- 1.2 and 2.2 on the IdP and Google side
- 2.1, 2.3, 2.4, 4.2, 5.1 and the Manage Team Bots part of 5.2
- parts of 7.1 and 7.2
- the Admin API reads documented as available on every plan

Whether Teams keys can call the PATCH and POST routes is unconfirmed (8.6).

Individual accounts, linked SuperGrok and X Premium+ accounts and Grok Business seats have member settings only (8.7), apart from Grok Business seat assignment (1.3) and Google-side app approval (2.2).

| Control | Cursor Enterprise | Cursor Teams (self-serve) | Individual, linked or Grok Business seat |
|---------|-------------------|---------------------------|------------------------------------------|
| 1.1 Limit to approved groups | ✅ Enable switch and Manage Group Access | Partial: team membership and IdP assignment only | ❌ |
| 1.2 IdP sign-in exception | ✅ (IdP-side; Entra passkey strength needs Team Setup) | ✅ (IdP-side) | ❌ |
| 1.3 Grok Business seats | n/a | n/a | ✅ console.x.ai seat assignment (self-serve Grok Business only) |
| 2.1 Connector policy | ✅ Team Marketplaces, MCP allowlist, audit pack | ✅ Team Marketplaces (no audit logs) | ❌ |
| 2.2 Google approval of Grok | ✅ (Google-side) | ✅ (Google-side) | ✅ (Google-side, for company Google accounts) |
| 2.3 Cloud Agents | ✅ | ✅ (API write unconfirmed) | ❌ |
| 2.4 Local execution ceiling | ✅ | ✅ (API write unconfirmed) | ❌ (member setting only) |
| 3.1 Network Controls | ✅ | ❌ | ❌ |
| 3.2 Allow Local Egress | ✅ | ❌ | ❌ |
| 3.3 Team Setup and Team Secrets | ✅ | ❌ | ❌ |
| 4.1 Enforce Auto-review | ✅ | ❌ | ❌ (personal rules only) |
| 4.2 Team Rules | ✅ | ✅ (API write unconfirmed) | ❌ |
| 4.3 Group Grok Bot tabs | ✅ | ❌ (no group tabs) | ❌ |
| 5.1 Public template sharing | ✅ (starts off) | ✅ (starts allowed; API write unconfirmed) | ❌ |
| 5.2 Team Bots (public beta) | ✅ Manage Team Bots and audit pack | Partial: Manage Team Bots only | ❌ |
| 6.1 Action Recording and OpenTelemetry | ✅ | ❌ | ❌ |
| 6.2 Audit logs | ✅ | ❌ | ❌ |
| 7.1 Offboarding | ✅ Delete VMs and Data, team removal, IdP revocation | Partial: team removal and IdP revocation; no data deletion | ❌ (account deletion under Cursor terms) |
| 7.2 Containment | ✅ Disable, Manage Group Access, Terminate | Partial: member removal, connector block, local-execution and Cloud Agent switches | ❌ |
| 7.3 Terminate Inactive Computers | ✅ (organization admins) | ❌ | ❌ |
| Admin API reads (`/access`, `/network`, `/auto-review`) | ✅ | ✅ (documented as every plan) | ❌ |
| Admin API writes | ✅ | Unconfirmed | ❌ |
| Organization API computer operations | ✅ (turned on per team by the account team) | ❌ | ❌ |
| SCIM | ✅ | ❌ | ❌ |

Grok Enterprise has no documented Grok Bot controls; access goes through the account manager.

---

## Appendix B: References

**xAI Grok Bot documentation (docs.x.ai):**
- [Grok Bot for teams and enterprises](https://docs.x.ai/grok-bot/teams-and-enterprises): availability, every admin control and the recommended baseline
- [Grok Bot security](https://docs.x.ai/grok-bot/security)
- [Grok Bot security FAQ](https://docs.x.ai/grok-bot/security-faq)
- [Team Bots](https://docs.x.ai/grok-bot/team-bots)
- [Configure identity and access](https://docs.x.ai/grok-bot/identity-and-access)
- [Manage Grok Bot computers](https://docs.x.ai/grok-bot/computers)
- [Connect to private networks](https://docs.x.ai/grok-bot/private-networks)
- [Settings and notifications](https://docs.x.ai/grok-bot/settings-and-notifications)
- [Approvals, security, and privacy](https://docs.x.ai/grok-bot/approvals-security-and-privacy)
- [Tag @bot on X](https://docs.x.ai/grok-bot/tag-on-x)
- [Create and manage Bots](https://docs.x.ai/grok-bot/bots)
- [Computer and apps](https://docs.x.ai/grok-bot/computer-and-apps)
- [Skills, routines, and automations](https://docs.x.ai/grok-bot/skills-routines-and-automations)

**xAI announcements and release notes:**
- [Introducing Grok Bot](https://x.ai/news/introducing-grok-bot) (2026-08-11)
- [Grok Bot is now included with more plans](https://x.ai/news/grok-bot-more-plans) (2026-08-26)
- [Grok Bot for Enterprise](https://x.ai/news/grok-bot-for-enterprise) (2026-09-03)
- [Team Bots](https://x.ai/news/team-bots) (2026-09-28)
- [Grok Bot changelog](https://x.ai/changelog/bot): returns a Cloudflare 403 to automated fetchers; read in a real browser on 2026-10-08 and re-read on 2026-10-09. Every changelog entry this guide cites (V0.30.0, V0.33.0, V0.37.0 of September 3, 2026, V0.53.0, V0.57.0, V0.64.0, V0.67.0, V0.68.0) rests on those reads

**xAI Grok Business and Management API:**
- [Grok Business management (console.x.ai)](https://docs.x.ai/grok/management)
- [Management API reference](https://docs.x.ai/developers/rest-api-reference/management)
- [Management API: billing](https://docs.x.ai/developers/rest-api-reference/management/billing)
- [Management API: audit](https://docs.x.ai/developers/rest-api-reference/management/audit)

**Cursor documentation (the Grok Bot admin plane):**
- [Cursor: Grok Bot for teams](https://cursor.com/docs/grok-bot/teams)
- [Cursor: Grok Bot security](https://cursor.com/docs/grok-bot/security)
- [Cursor: Grok Bot deployment](https://cursor.com/docs/grok-bot/deployment): MDM reaches only the apps; the hosted computer is not MDM-enrolled
- [Cursor: Grok Bot settings](https://cursor.com/docs/grok-bot/settings)
- [Cursor: Manage Grok Bot computers](https://cursor.com/docs/grok-bot/computers)
- [API overview](https://cursor.com/docs/api)
- [Admin API: Grok Bot](https://cursor.com/docs/account/teams/admin-api#grok-bot)
- [Admin API: audit logs](https://cursor.com/docs/account/teams/admin-api#get-audit-logs)
- [Admin API](https://cursor.com/docs/account/teams/admin-api) (remove-member, members, billing groups, model-access configuration)
- [Billing groups](https://cursor.com/docs/account/enterprise/billing-groups)
- [Organization API: Grok Bot computers](https://cursor.com/docs/account/organizations/organization-admin-api#grok-bot-computers)
- [Compliance and monitoring (audit logs)](https://cursor.com/docs/enterprise/compliance-and-monitoring)
- [OpenTelemetry Export](https://cursor.com/docs/enterprise/opentelemetry-export)
- [OpenTelemetry Export: wire reference](https://cursor.com/docs/enterprise/opentelemetry-export/wire)
- [Model and integration management](https://cursor.com/docs/enterprise/model-and-integration-management)
- [Plugins and Team Marketplaces](https://cursor.com/docs/plugins)
- [Plugins reference: marketplace manifest](https://cursor.com/docs/reference/plugins#marketplace-manifest-fields)
- [SCIM](https://cursor.com/docs/account/teams/scim)
- [SSO](https://cursor.com/docs/account/teams/sso)
- [Identity and access management](https://cursor.com/docs/enterprise/identity-and-access-management)

**Cursor help center:**
- [Plans and billing](https://cursor.com/help/grok-bot/plans)
- [SuperGrok and Grok Bot](https://cursor.com/help/grok-bot/supergrok)
- [Connect plugins](https://cursor.com/help/grok-bot/connect-plugins)
- [Team Bots](https://cursor.com/help/grok-bot/team-bots)
- [Group chats and Bot-to-Bot messages](https://cursor.com/help/grok-bot/group-chats)
- [Routines](https://cursor.com/help/grok-bot/routines)
- [Models](https://cursor.com/help/grok-bot/models)
- [Sign-in domains](https://cursor.com/help/troubleshooting/sign-in-domains)

**Automation surface census (all fetched 2026-10-08):**
- [Terraform registry: cursor/cursor](https://registry.terraform.io/v1/providers/cursor/cursor): 0.8.0 has only `origin_*` and `platform_workflow` resources and data sources, nothing for Grok Bot
- [Terraform registry: xai namespace](https://registry.terraform.io/v2/providers?filter%5Bnamespace%5D=xai): zero providers (the spacexai namespace is also empty)
- [okta/okta 7.0.0: okta_app_signon_policy_rule](https://registry.terraform.io/v2/provider-docs/13337260), [okta_app_signon_policy data source](https://registry.terraform.io/v2/provider-docs/13337141), [okta_app_sign_on_policy_rule data source](https://registry.terraform.io/v2/provider-docs/13337140) and [okta_everyone_group data source](https://registry.terraform.io/v2/provider-docs/13337178), used by the 1.2 pack
- [Terraform: checks](https://developer.hashicorp.com/terraform/language/checks) ("Terraform reports a warning and continues") and [custom conditions](https://developer.hashicorp.com/terraform/language/expressions/custom-conditions) (a failed postcondition stops the operation), which decide how the 1.2 read-back fails
- [Okta Management API spec](https://github.com/okta/okta-management-openapi-spec/blob/master/dist/current/management-minimal.yaml) (2026.09.2): OAuth scopes and the `PolicyPlatformOperatingSystemType` enum
- [hashicorp/azuread 3.10.0: azuread_conditional_access_policy](https://registry.terraform.io/v2/provider-docs/13798576), used by the 1.2 pack
- [hashicorp/googleworkspace](https://registry.terraform.io/v1/providers/hashicorp/googleworkspace): no third-party app-access resource
- [xAI CLI reference](https://docs.x.ai/build/cli/reference) and [Grok Build overview](https://docs.x.ai/build/overview): the `grok` CLI is the Grok Build coding agent, with no Grok Bot or org-admin subcommands
- [Cursor CLI overview](https://cursor.com/docs/cli/overview): no Grok Bot verbs
- [Cursor TypeScript SDK](https://cursor.com/docs/sdk/typescript): no Grok Bot surface, and "Team Admin API keys are not yet supported"
- [xai-sdk-python](https://github.com/xai-org/xai-sdk-python): no license-assignment or seat-management module
- [xAI Organization (console.x.ai)](https://docs.x.ai/grok/organization): SCIM role-to-license provisioning, "exclusive to the Enterprise tier"

**Identity provider and Google Workspace documentation:**
- [Okta: add an app sign-in policy rule](https://help.okta.com/oie/en-us/content/topics/identity-engine/policies/add-app-sign-on-policy-rule.htm)
- [Microsoft: Conditional Access conditions](https://learn.microsoft.com/en-us/entra/identity/conditional-access/concept-conditional-access-conditions)
- [Microsoft: Building a Conditional Access policy](https://learn.microsoft.com/en-us/entra/identity/conditional-access/concept-conditional-access-policies)
- [Microsoft: Conditional Access users and groups](https://learn.microsoft.com/en-us/entra/identity/conditional-access/concept-conditional-access-users-groups)
- [Microsoft: Conditional Access target resources](https://learn.microsoft.com/en-us/entra/identity/conditional-access/concept-conditional-access-cloud-apps)
- [Microsoft: assign users and groups to an enterprise app](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/assign-user-or-group-access-portal)
- [Microsoft: require MFA strength for all users](https://learn.microsoft.com/en-us/entra/identity/conditional-access/policy-all-users-mfa-strength)
- [Google: control which third-party and internal apps access Google Workspace data](https://knowledge.workspace.google.com/admin/apps/control-which-third-party-and-internal-apps-access-google-workspace-data)
- [Google: review and manage third-party app access requests](https://knowledge.workspace.google.com/admin/apps/review-and-manage-third-party-app-access-requests)
- [Google: add and configure third-party apps in bulk](https://knowledge.workspace.google.com/admin/apps/add-and-configure-third-party-apps-in-bulk)
- [Cloud Identity Policy API: supported settings](https://docs.cloud.google.com/identity/docs/concepts/supported-policy-api-settings)

**Benchmarks and frameworks:**
- [CISA ScubaGear Entra ID (AAD) baseline](https://raw.githubusercontent.com/cisagov/ScubaGear/main/PowerShell/ScubaGear/baselines/aad.md)
- [OWASP Top 10 for Agentic Applications (launch post)](https://genai.owasp.org/2025/12/09/owasp-top-10-for-agentic-applications-the-benchmark-for-agentic-security-in-the-age-of-autonomous-ai/)
- [OWASP LLM06:2025 Excessive Agency](https://genai.owasp.org/llmrisk/llm062025-excessive-agency/)

**Security research and incidents:**
- [The lethal trifecta, Simon Willison (2025-06-16)](https://simonwillison.net/2025/Jun/16/the-lethal-trifecta/)
- [CVE-2025-54135 CNA record (CVE Program API)](https://cveawg.mitre.org/api/cve/CVE-2025-54135)
- [Adversa AI: Cryptographic Context Injection against Grok (2026-08-20)](https://adversa.ai/blog/cryptographic-context-injection-grok-data-theft/)
- [Radware: ShadowLeak (2025-09-18)](https://www.radware.com/blog/threat-intelligence/shadowleak/): bot wall to automated fetchers; read in a real browser on 2026-10-08
- [Radware: ZombieAgent (2026-01-08)](https://www.radware.com/blog/threat-intelligence/zombieagent/): read in a real browser on 2026-10-08
- [NeuralTrust: Grok chatbot and Bankrbot Morse-code transfer (2026-05-08)](https://neuraltrust.ai/blog/grok-morse-code)
- [Brave: research PoC of agentic browser prompt injection in Perplexity Comet (2025-08-20)](https://brave.com/blog/comet-prompt-injection/)
- [DISA STIG Document Library](https://www.cyber.mil/stigs/downloads): JavaScript-rendered; searched in a real browser on 2026-10-09
- [PromptArmor: data exfiltration from Slack AI (August 2024)](https://www.promptarmor.com/resources/data-exfiltration-from-slack-ai-via-indirect-prompt-injection)
- [KrebsOnSecurity: xAI dev leaks API key (2025-05-01)](https://krebsonsecurity.com/2025/05/xai-dev-leaks-api-key-for-private-spacex-tesla-llms/)

**Related How to Harden guides:**
- [Cursor](/guides/cursor/): org-wide SSO, SCIM, Privacy Mode, MCP allowlist, Cloud Agents, network allowlist, audit export and spend
- [ChatGPT Enterprise, section 6](/guides/chatgpt-enterprise/#6-workspace-agents-hardening): the workspace-agent hardening pattern and the lethal-trifecta framing
- [Okta](/guides/okta/), [Microsoft Entra ID](/guides/microsoft-entra-id/), [Google Workspace](/guides/google-workspace/), [Slack](/guides/slack/)

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-10-09 | 0.1.0 | ai-drafted | Initial guide: 20 controls in 7 sections (access and identity, agent reach and connected apps, hosted computer and network, autonomy and approvals, sharing and Team Bots, monitoring and audit, lifecycle and containment), plus an unleveled Known Gaps and Member Guidance section, Compliance Quick Reference, plan availability and references. 17 controls carry Code Pack includes (16 api and 1 terraform, plus 13 Sigma rules); 1.3, 2.2 and 7.3 carry evidenced ClickOps-only verdicts, and 2.1, 4.3, 5.2 and 6.2 enforce through ClickOps with read-only packs. Drafted from vendor documentation fetched 2026-10-08 and corrected after an independent review against pages re-fetched 2026-10-09; no tenant was observed | Claude Code (Opus 5.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)

