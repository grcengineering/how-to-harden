---
layout: default
title: "Ona source-first coverage reconciliation"
permalink: /research/ona-source-coverage/
---

# Ona source-first coverage reconciliation

Scope: Ona’s independently administered organization, Cloud/customer-managed runners, Codex Agent, environments, Automations, integrations, installed clients and programmatic surfaces. Research began before edits on 2026-11-05; original guide 0.2.2 had 22 controls, 20 includes and 48 files. No tenants or credentials were accessed. Historical 2026-08-19 evidence is not a new live validation.

## Product, lifecycle and release evidence

- [Ona ownership](https://ona.com/stories/ona-joins-openai), fetched via web: transaction closed 2026-08-10; own console/identity/contracts remain separate from ChatGPT. [Quickstart](https://ona.com/docs/ona/quickstart) records closed new-customer signup, existing deployments/members supported.
- [Complete documentation index](https://ona.com/docs/llms.txt), fetched/read via web, 751 lines: organization identity/policy, Codex/model routing, Cloud and AWS/GCP runners, projects/prebuilds/storage, CLI/SDK/API/config, integrations/skills, Automations and audit. Index candidates below are reconciled independently of old headings.
- [Product changelog](https://ona.com/docs/changelog), fetched via web/search: October 28 security update Ona Desktop 20261027.1288, macOS 13+; older omissions include signed CLI provenance, creator-only port fallback, multi-GitHub installation and model-routing behavior.
- [Provider setup](https://ona.com/docs/ona/integrations/terraform-provider) says stable 0.5.0; current [registry versions](https://registry.terraform.io/v1/providers/gitpod-io/ona/versions) independently returns stable 0.5.1 and 0.5.0, 58 total versions. Published tag v0.5.1 resolves 699015b2201a451600988a92c067794b72373c94, same as current main; every selected body fetched successfully. Prefer exact 0.5.1 pin for security dependency fixes. Terraform >=1.14; Linux amd64/arm64 packages only. No macOS native validation claim.

## Six-surface census and decisions

| Surface | Evidence / read-write / disposition |
|---------|------------------------------------|
| Terraform | Full v0.5.1 resource/data-source census below; 34 resources and 11 data sources plus 3 operational guides. Read data sources need the real token permissions; write plans need read-write PAT unless Support confirms service-account writes. Built-in integration auth overrides removed; runner_policy removed in 0.4 migration. Native provider validate is pending Linux CI; no plan/apply. |
| API | [Generated reference](https://ona.com/docs/api-reference) is current Connect RPC: POST also performs reads; tokens inherit actor rights; unknown fields rejected, streaming needs Connect envelopes. Existing read-only packs retain their earlier evidence; current org-policy/provider fields reconciled. Preview org automationPolicy write contract remains unverified, not absent. Per-Automation writes are documented/provider-managed. |
| CLI | [CLI](https://ona.com/docs/ona/integrations/cli) and [reference](https://ona.com/docs/ona/reference/cli): environment, SSH, ports, automation, webhook, user, org/security-policy paths; read vs write depends on command, not HTTP verb. No CLI installed or product command executed. SLSA installer aborts on verification failure; in-environment CLI starts with limited auth. Explicit creator_only port admission fails closed instead of older-runner public fallback. |
| SDK | [Current SDK](https://ona.com/docs/ona/integrations/sdk): Enterprise, Python/TypeScript/Go; 1.x incompatible with 0.x; TypeScript @gitpod/sdk Node20+, ONA_API_KEY/ONA_BASE_URL. Low-level management vs high-level environment/command/file/agent operations; creating a high-level client workflow is not a harmless audit. No SDK pack added without a distinct control benefit. |
| Config | Dev Containers, .ona/config.yaml tasks/services/Automations-as-code, repo/organization skills, AGENTS.md, dotfiles and .ona/mcp-config.json are independently executable/instruction surfaces. Covered 2.3, 3.5, 4.5. Repo skills override organization then built-ins. No prompt template counts as an enforced security policy. |
| SIEM | Existing audit export/real prior event schema retained as historical evidence, preview/gate errors remain preconditions. Veto events only report matched rules and may be preview-gated. Exact current retention/training commitments remain contract questions; no inference from WatchEvents. |

## Source-derived candidates before control selection

| Candidate / fetched primary source | Defaults, conditions, lifecycle / disposition |
|-----------------------------------|---------------------------------------------|
| [SCIM](https://ona.com/docs/ona/scim/overview), [SCIM restriction](https://ona.com/docs/ona/organizations/policies/scim-account-restriction) | Enterprise beta, linked active SSO required; token groups scoped to SCIM config, users to linked SSO; same-SSO configs share user scope, cross-scope404. New-signin restriction does not remove existing members. Correct1.2; changed ClickOps loses old live badge. |
| [Veto Exec](https://ona.com/docs/ona/organizations/policies/executable-deny-list) | Enterprise; defaultallow, rulesAudit/Block; inactive creation vs assigned default/new-start enforcement. Hash failures fail open, safelisted binaries cannot block, unresolved selectors cannot enforce. Correct2.1 and native default validation; matched audit events only. |
| [Command deny](https://ona.com/docs/ona/command-deny-list) | Agent commands only; manual terminal unaffected, slash commands become prompts, new/restarted sessions. Covered2.2 with current limits. |
| [Codex](https://ona.com/docs/ona/agents/codex), [model access](https://ona.com/docs/ona/agents/llm-providers/overview), [ChatGPT connection](https://ona.com/docs/ona/integrations/configure-codex) | Cloud defaultOpenAI, supported managed runners use approved model route; new directOpenAI/BedrockRuntime/Mantle supported, prior blanketBedrockdeprecation incorrect. Models/reasoning/Fast independently governed; older environments do not auto-upgrade. Goal mode defaulton; connection disconnect falls back to orgmodelroute, not runtime stop. Correct2.4, add2.7. |
| [Automation limits](https://ona.com/docs/ona/automations/guardrails), [sharing](https://ona.com/docs/ona/automations/sharing-automations) | SelectedEnterprise orglimits preview, Admin/AutomationsAdmin bypassorgnotplanlimits. Onlyorgadminsshare despite table wording; Everyone=Executor, pergroupEnterprise. Invocation identity/SCM differs from creator; explicit executor config separately retained. Correct2.5, add2.8 with role-assignment nativepack. |
| [Persistent storage](https://ona.com/docs/ona/environments/persistent-storage), [project visibility](https://ona.com/docs/ona/projects/project-sharing) | Stop/archive retain disk; rebuild retains repo/bind mounts; prebuild wholefilesystem snapshots. Enterpriseprojectadminonlydefault, othertiersorgdefault; projectsharing does not changeSCMrights. Add3.6 and4.5. |
| [Browser](https://ona.com/docs/ona/integrations/web-browser), [CLI](https://ona.com/docs/ona/integrations/cli) | Defaultonalltiers; Enterprise toggledoesnotdisableport/editor/VSCodeBrowser. Portopen implicitprivate mayfallbackpublicolderrunner; explicitcreator_onlyfailclosed. Correct3.1/3.2 and changed ClickOps evidence. |
| [Slack](https://ona.com/docs/ona/integrations/configure-slack) | Initialwebopen/MDfailed; official-domain search fallback delivered complete body. Admininstall+userlink, linkeduserrole/projectrights, initiatinguserownsthread, editsnotnewprompt, pendingrequestresumesafterlink. Add4.4; exactOAuthscope/replaycontractnotdocumentedhere. |
| [GitHub PR mentions](https://ona.com/docs/ona/integrations/github-pr-mentions) | LinkedGitHubuseridentity, selectedrepos+OnaProject, forksignored, responseAppvscommituseractors, Core/Enterpriseenablement. Add4.4. |
| [Atlassian](https://ona.com/docs/ona/integrations/configure-atlassian), [Notion](https://ona.com/docs/ona/integrations/configure-notion), [Sentry](https://ona.com/docs/ona/integrations/configure-sentry), [Granola](https://ona.com/docs/ona/integrations/configure-granola) | Adminenable+personalOAuth; AtlassianRovoMCPdomainallowlist, Notionpages/databases/write, Sentryprojectselection, Granolameeting/transcriptaccess. Add4.4 differentiatedtable; exactconsentscopes/revoke/retentionneedactualsourceverification, notguessednames. |
| [Repository skills](https://ona.com/docs/ona/agents/skills), [org skills](https://ona.com/docs/ona/skills), [Dev Container](https://ona.com/docs/ona/configuration/devcontainer/overview) | Repo>org>builtin precedence; automaticdiscovery; startup/image/features/AGENTS instructions attacker-influenced. Add4.5; nativeorgskillprovideravailable, no redundantpromptsasconfigpack. |
| [Provider state](https://ona.com/docs/ona/integrations/terraform-provider) and allcurrentprovideroperationalguides | sensitive doesnotexcludestate; writeonly/ephemeralwhereavailable; runnerregistrationtoken24h/singleusestoredstate; orgpoliciessingleton/destroyrestoresinitialserverconfig. Add5.2; preventfalseindependentmodulesclaim. |
| [Desktop security update](https://ona.com/docs/changelog), CLI integrity/auth docs | VersionfloorandmacOSrequirement; credentialsstoredlocally; do notupgradein-environmentlimitedauthwithoutneed. Add5.3. OrganizationdesktopMDMcontractnotverified. |
| [Teams](https://ona.com/docs/ona/organizations/teams), budgets/insights indexed | Teams are reporting/cost targets, not ACL; groups control access. Explain1.3. Costlimits/metricscoveredasoperations; nofinancialplanningorchartfeaturesasstandalonecontrols. |
| Image/diagram/editor/workflow and cloudcapacity/howto index pages | Context/outputoroperations features rather than independentsecuritycontrolplanes. Govern executableinstructions, thirdpartytools, sharing, identity/egress/retention through existing/new controls; no marketingstubs. |

## Full stable-provider inventory

Every row below was fetched on 2026-11-05 from the published v0.5.1 tag, not assumed from a resource count. “Adjacent” means reviewed but no separate hardening step justified; it is not unsupported.

| Type / name | Exact source | Disposition |
|-------------|--------------|-------------|
| Data source: automations | [v0.5.1](https://raw.githubusercontent.com/gitpod-io/terraform-provider-ona/v0.5.1/docs/data-sources/automations.md) | Covered 2.5, 2.8 |
| Data source: integration_definitions | [v0.5.1](https://raw.githubusercontent.com/gitpod-io/terraform-provider-ona/v0.5.1/docs/data-sources/integration_definitions.md) | Covered 4.4 |
| Data source: project | [v0.5.1](https://raw.githubusercontent.com/gitpod-io/terraform-provider-ona/v0.5.1/docs/data-sources/project.md) | Covered 3.6, 4.5 |
| Data source: runner | [v0.5.1](https://raw.githubusercontent.com/gitpod-io/terraform-provider-ona/v0.5.1/docs/data-sources/runner.md) | Covered 5.1 |
| Data source: runners | [v0.5.1](https://raw.githubusercontent.com/gitpod-io/terraform-provider-ona/v0.5.1/docs/data-sources/runners.md) | Covered 5.1 |
| Data source: security_policies | [v0.5.1](https://raw.githubusercontent.com/gitpod-io/terraform-provider-ona/v0.5.1/docs/data-sources/security_policies.md) | Covered 2.1 |
| Data source: skill | [v0.5.1](https://raw.githubusercontent.com/gitpod-io/terraform-provider-ona/v0.5.1/docs/data-sources/skill.md) | Covered 4.5 |
| Data source: user | [v0.5.1](https://raw.githubusercontent.com/gitpod-io/terraform-provider-ona/v0.5.1/docs/data-sources/user.md) | Covered 1.3 |
| Data source: users | [v0.5.1](https://raw.githubusercontent.com/gitpod-io/terraform-provider-ona/v0.5.1/docs/data-sources/users.md) | Covered 1.3 |
| Data source: warm_pool | [v0.5.1](https://raw.githubusercontent.com/gitpod-io/terraform-provider-ona/v0.5.1/docs/data-sources/warm_pool.md) | Adjacent operational object; apply identity, sharing, lifecycle and state controls1.3/3.3/4.5/5.2; no new setting claimed |
| Data source: warm_pools | [v0.5.1](https://raw.githubusercontent.com/gitpod-io/terraform-provider-ona/v0.5.1/docs/data-sources/warm_pools.md) | Adjacent operational object; apply identity, sharing, lifecycle and state controls1.3/3.3/4.5/5.2; no new setting claimed |
| Resource: announcement_banner | [v0.5.1](https://raw.githubusercontent.com/gitpod-io/terraform-provider-ona/v0.5.1/docs/resources/announcement_banner.md) | Adjacent operational object; apply identity, sharing, lifecycle and state controls1.3/3.3/4.5/5.2; no new setting claimed |
| Resource: automation | [v0.5.1](https://raw.githubusercontent.com/gitpod-io/terraform-provider-ona/v0.5.1/docs/resources/automation.md) | Covered 2.5 |
| Resource: automation_role_assignment | [v0.5.1](https://raw.githubusercontent.com/gitpod-io/terraform-provider-ona/v0.5.1/docs/resources/automation_role_assignment.md) | Covered 2.8 |
| Resource: custom_domain | [v0.5.1](https://raw.githubusercontent.com/gitpod-io/terraform-provider-ona/v0.5.1/docs/resources/custom_domain.md) | Adjacent operational object; apply identity, sharing, lifecycle and state controls1.3/3.3/4.5/5.2; no new setting claimed |
| Resource: environment_class | [v0.5.1](https://raw.githubusercontent.com/gitpod-io/terraform-provider-ona/v0.5.1/docs/resources/environment_class.md) | Adjacent operational object; apply identity, sharing, lifecycle and state controls1.3/3.3/4.5/5.2; no new setting claimed |
| Resource: git_authentication | [v0.5.1](https://raw.githubusercontent.com/gitpod-io/terraform-provider-ona/v0.5.1/docs/resources/git_authentication.md) | Adjacent operational object; apply identity, sharing, lifecycle and state controls1.3/3.3/4.5/5.2; no new setting claimed |
| Resource: github_app_integration | [v0.5.1](https://raw.githubusercontent.com/gitpod-io/terraform-provider-ona/v0.5.1/docs/resources/github_app_integration.md) | Covered 4.3–4.4 |
| Resource: group | [v0.5.1](https://raw.githubusercontent.com/gitpod-io/terraform-provider-ona/v0.5.1/docs/resources/group.md) | Covered 1.3 |
| Resource: group_membership | [v0.5.1](https://raw.githubusercontent.com/gitpod-io/terraform-provider-ona/v0.5.1/docs/resources/group_membership.md) | Covered 1.3 |
| Resource: integration | [v0.5.1](https://raw.githubusercontent.com/gitpod-io/terraform-provider-ona/v0.5.1/docs/resources/integration.md) | Covered 4.4 |
| Resource: oidc_config | [v0.5.1](https://raw.githubusercontent.com/gitpod-io/terraform-provider-ona/v0.5.1/docs/resources/oidc_config.md) | Adjacent operational object; apply identity, sharing, lifecycle and state controls1.3/3.3/4.5/5.2; no new setting claimed |
| Resource: organization_ai_budget | [v0.5.1](https://raw.githubusercontent.com/gitpod-io/terraform-provider-ona/v0.5.1/docs/resources/organization_ai_budget.md) | Adjacent operational object; apply identity, sharing, lifecycle and state controls1.3/3.3/4.5/5.2; no new setting claimed |
| Resource: organization_policies | [v0.5.1](https://raw.githubusercontent.com/gitpod-io/terraform-provider-ona/v0.5.1/docs/resources/organization_policies.md) | Covered 1.2, 2.2–2.4, 3.2–3.4 |
| Resource: organization_role_assignment | [v0.5.1](https://raw.githubusercontent.com/gitpod-io/terraform-provider-ona/v0.5.1/docs/resources/organization_role_assignment.md) | Covered 1.3 |
| Resource: project | [v0.5.1](https://raw.githubusercontent.com/gitpod-io/terraform-provider-ona/v0.5.1/docs/resources/project.md) | Covered 3.6, 4.5 |
| Resource: project_role_assignment | [v0.5.1](https://raw.githubusercontent.com/gitpod-io/terraform-provider-ona/v0.5.1/docs/resources/project_role_assignment.md) | Covered 4.5 |
| Resource: runner | [v0.5.1](https://raw.githubusercontent.com/gitpod-io/terraform-provider-ona/v0.5.1/docs/resources/runner.md) | Covered 5.1 |
| Resource: runner_llm_integration | [v0.5.1](https://raw.githubusercontent.com/gitpod-io/terraform-provider-ona/v0.5.1/docs/resources/runner_llm_integration.md) | Covered 2.4 |
| Resource: runner_role_assignment | [v0.5.1](https://raw.githubusercontent.com/gitpod-io/terraform-provider-ona/v0.5.1/docs/resources/runner_role_assignment.md) | Covered 1.3, 5.1 |
| Resource: runner_token | [v0.5.1](https://raw.githubusercontent.com/gitpod-io/terraform-provider-ona/v0.5.1/docs/resources/runner_token.md) | Covered 5.1, 5.2 |
| Resource: scim_configuration | [v0.5.1](https://raw.githubusercontent.com/gitpod-io/terraform-provider-ona/v0.5.1/docs/resources/scim_configuration.md) | Covered 1.2 |
| Resource: scm_integration | [v0.5.1](https://raw.githubusercontent.com/gitpod-io/terraform-provider-ona/v0.5.1/docs/resources/scm_integration.md) | Covered 4.3 |
| Resource: secret | [v0.5.1](https://raw.githubusercontent.com/gitpod-io/terraform-provider-ona/v0.5.1/docs/resources/secret.md) | Adjacent operational object; apply identity, sharing, lifecycle and state controls1.3/3.3/4.5/5.2; no new setting claimed |
| Resource: security_policy | [v0.5.1](https://raw.githubusercontent.com/gitpod-io/terraform-provider-ona/v0.5.1/docs/resources/security_policy.md) | Covered 2.1, 3.1 |
| Resource: service_account | [v0.5.1](https://raw.githubusercontent.com/gitpod-io/terraform-provider-ona/v0.5.1/docs/resources/service_account.md) | Covered 1.4 |
| Resource: skill | [v0.5.1](https://raw.githubusercontent.com/gitpod-io/terraform-provider-ona/v0.5.1/docs/resources/skill.md) | Covered 4.5 |
| Resource: sso_configuration | [v0.5.1](https://raw.githubusercontent.com/gitpod-io/terraform-provider-ona/v0.5.1/docs/resources/sso_configuration.md) | Covered 1.1 |
| Resource: team | [v0.5.1](https://raw.githubusercontent.com/gitpod-io/terraform-provider-ona/v0.5.1/docs/resources/team.md) | Adjacent operational object; apply identity, sharing, lifecycle and state controls1.3/3.3/4.5/5.2; no new setting claimed |
| Resource: team_ai_budget | [v0.5.1](https://raw.githubusercontent.com/gitpod-io/terraform-provider-ona/v0.5.1/docs/resources/team_ai_budget.md) | Adjacent operational object; apply identity, sharing, lifecycle and state controls1.3/3.3/4.5/5.2; no new setting claimed |
| Resource: team_membership | [v0.5.1](https://raw.githubusercontent.com/gitpod-io/terraform-provider-ona/v0.5.1/docs/resources/team_membership.md) | Adjacent operational object; apply identity, sharing, lifecycle and state controls1.3/3.3/4.5/5.2; no new setting claimed |
| Resource: terms_of_service | [v0.5.1](https://raw.githubusercontent.com/gitpod-io/terraform-provider-ona/v0.5.1/docs/resources/terms_of_service.md) | Adjacent operational object; apply identity, sharing, lifecycle and state controls1.3/3.3/4.5/5.2; no new setting claimed |
| Resource: user_ai_budget | [v0.5.1](https://raw.githubusercontent.com/gitpod-io/terraform-provider-ona/v0.5.1/docs/resources/user_ai_budget.md) | Adjacent operational object; apply identity, sharing, lifecycle and state controls1.3/3.3/4.5/5.2; no new setting claimed |
| Resource: warm_pool | [v0.5.1](https://raw.githubusercontent.com/gitpod-io/terraform-provider-ona/v0.5.1/docs/resources/warm_pool.md) | Adjacent operational object; apply identity, sharing, lifecycle and state controls1.3/3.3/4.5/5.2; no new setting claimed |
| Resource: webhook | [v0.5.1](https://raw.githubusercontent.com/gitpod-io/terraform-provider-ona/v0.5.1/docs/resources/webhook.md) | Covered 6.2 |

## Verified findings

- CORRECTION | Veto guarantees | Document hashfailopen/safelist/materialization/starttiming, nativeallowdefault | https://ona.com/docs/ona/organizations/policies/executable-deny-list |2.1
- CORRECTION | Provider routes | Current OpenAI/Bedrock routes supported; connectionfallbackisnotstop | https://ona.com/docs/ona/agents/llm-providers/overview |2.4/2.7
- OMISSION | Shared automation/integration identities | Separate invocation, trigger, sourceconsent and sharing | https://ona.com/docs/ona/automations/sharing-automations |2.8/4.4
- OMISSION | Persisted runtime/config/state | Prebuildsnapshot, skillspriority, TFcredentials/destroy and clientpatching | https://ona.com/docs/ona/environments/persistent-storage |3.6/4.5/5.2/5.3
- CORRECTION | Webhookdirection | Ona receives/validates signedSCMpayloads, not signsoutbound | https://ona.com/docs/ona/automations/webhooks |6.2packcomments

## Validation and remaining research limits

No live tenant, CLI, SDK workflow, providerplan/apply, productinstall or credential creation was performed. Existing live badges remain only on unchanged historically exercised surfaces; current changed console instructions lose their prior badge. Whole-native-provider validation requires Linux; this macOS host has no Docker daemon. Local fmt, static source-contract reconciliation and offline fixtures are separate from Linux CI/tenant evidence. New exact integrationOAuthscopes, revocation endpoints, replaywindows and any undocumentedorganizationautomationpolicywrite remain unverified research gaps.

## API transport correction

All 20 existing API entrypoints now share bounded, credential-safe HTTPS transport with curlrc disabled, private staging, redacted failures and complete-pagination publication. Omitted proto3 repeated fields remain valid, while required organization messages fail closed when absent. Optional ONA_OUTPUT uses a new private file in an owned private parent outside the checkout. Tests use fake curl against fixed vendor destinations, with no HTTP/loopback bypass. The changed transport invalidates former live API badges; the August history remains dated evidence. See the [family validation record](/research/openai-refresh-validation/) for actual offline and CI results.

## Native provider validation follow-up

The initial [Linux job at f200c1c](https://github.com/grcengineering/how-to-harden/actions/runs/42089450314/job/127463336770) initialized the published 0.5.1 provider and validated the first 15 recipes, then stopped at 4.3 with `Missing OAuth Client ID`. The complete authenticated job log was read through the GitHub connector. This is the previously documented unknown-value artifact, not a missing production input: the template already requires the operator's client ID without a default.

The exact [published implementation](https://github.com/gitpod-io/terraform-provider-ona/blob/699015b2201a451600988a92c067794b72373c94/internal/provider/runner/scm_integration_resource.go#L516), fetched as the unchanged v0.5.1 source, rejects an unknown client ID during `ValidateConfig`. The production recipe remains unchanged. The CI gate now requires the precise single direct-root diagnostic and separately validates the actual recipe as a child module with temporary synthetic literal inputs: a configured ID must pass and an empty ID must fail through the native provider. No provider is replaced, and no plan/apply or vendor credential is used. Every one of the 20 recipes is attempted and any unexpected failure fails the aggregate gate.

Local fixture regressions check that the exception cannot hide another native diagnostic, accept an empty ID, stop later recipes after an early failure or narrow the 20-recipe census. These fixtures test the gate's control flow; actual native results remain the Linux job's responsibility. Supplemental Darwin compilation from the unchanged tag was attempted but blocked by official Go-proxy socket/timeouts, so no native Darwin-provider result is claimed and the published Linux-only support statement is unchanged.
