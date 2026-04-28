# Vendor First-Party CLI Inventory

**Purpose:** Authoritative reference for which How-To-Harden vendors publish first-party command-line tools, used to drive accurate Code Pack creation under `packs/{vendor}/cli/`.

**Method:** Live verification via WebSearch + WebFetch against vendor docs. Last refreshed: **2026-04-25**.

**Status legend:**
- **GA-Official** — vendor explicitly supports as a product
- **Vendor-Published / Not Officially Supported** — published in vendor's GitHub org with "not officially supported" disclaimer; functionally first-party
- **Vendor-Adjacent (narrow scope)** — official CLI exists but only covers app-dev / endpoint-only / SDK-publishing, not admin/security ops
- **Deprecated** — vendor announced end of support
- **PowerShell-Only** — Microsoft pattern; PS modules count as first-party
- **None** — no first-party CLI; admin/security automation requires REST API, Terraform, or PowerShell module

---

## Master Vendor Inventory

| # | Vendor | Status | CLI Name | Install (canonical) | Covers Admin/Security Ops? | Source |
|---|--------|--------|----------|--------------------|----------------------------|--------|
| 1 | 1Password | GA-Official | `op` | `brew install --cask 1password-cli` | Yes — vault/group provisioning, SCIM bridge, service accounts, secret injection | https://developer.1password.com/docs/cli/ |
| 2 | Abnormal Security | None | — | — | API-only | https://abnormal.ai/ |
| 3 | ADP | None | — | — | API-only (OAuth/cert) | https://developers.adp.com/ |
| 4 | Airtable | Vendor-Adjacent | `block` (`@airtable/blocks-cli`) | `npm i -g @airtable/blocks-cli` | No — extension publishing only | https://www.npmjs.com/package/@airtable/blocks-cli |
| 5 | Amplitude | Vendor-Adjacent | `ampli` | `brew tap amplitude/ampli && brew install ampli` | No — tracking-plan sync only | https://amplitude.com/docs/sdks/ampli/ampli-cli |
| 6 | Anthropic Claude | GA-Official | `claude` (Claude Code) | `npm install -g @anthropic-ai/claude-code` (npm now deprecated; native installer preferred) | Partial — local agent permissions/MCP/hooks; no org-admin (SSO/audit via Console) | https://code.claude.com/docs/en/setup |
| 7 | Asana | None | — | — | API-only | https://developers.asana.com/ |
| 8 | Atlassian (Jira/Confluence) | GA-Official | `acli` | `brew install atlassian/acli/acli` | Partial — work-item ops, OAuth scopes, Rovo Dev (beta); admin/SSO via REST | https://developer.atlassian.com/cloud/acli/ |
| 9 | Auth0 | GA-Official | `auth0` + `auth0-deploy-cli` | `brew tap auth0/auth0-cli && brew install auth0` | Yes — tenant config, log streams, action/rule deploy, branding, custom domains | https://auth0.github.io/auth0-cli/ |
| 10 | AWS IAM Identity Center | GA-Official | `aws sso-admin` (in AWS CLI v2) | `brew install awscli` | Yes — permission sets, account assignments, identity store ops | https://docs.aws.amazon.com/cli/latest/reference/sso-admin/ |
| 11 | Azure DevOps | GA-Official | `az devops` extension | `az extension add --name azure-devops` | Yes — service connections, OIDC federation, branch policies, variable groups, agent pools, PAT mgmt | https://learn.microsoft.com/en-us/azure/devops/cli/ |
| 12 | BambooHR | None | — | — | API-only | https://documentation.bamboohr.com/ |
| 13 | BeyondTrust Password Safe | GA-Official | `ps-cli` | `pip install beyondtrust-bips-cli` | Yes — safes, folders, secrets, managed accounts, ISA requests | https://docs.beyondtrust.com/bips/docs/ps-cli-application |
| 14 | Bitbucket | None | — | — | **No first-party CLI**. Atlassian's `acli` does NOT cover Bitbucket as of Apr 2026. Use REST API or Atlassian Terraform provider. | https://developer.atlassian.com/cloud/bitbucket/rest/ |
| 15 | Box | GA-Official | `box` (`@box/cli`) | `npm i -g @box/cli` | Yes — bulk user/group provisioning, collaboration roles, audit log retrieval, retention via API endpoints | https://developer.box.com/guides/tooling/cli/ |
| 16 | Braze | None | — | — | REST API + Cloud Data Ingestion only | https://www.braze.com/docs/developer_guide/home |
| 17 | Buildkite | GA-Official | `bk` (+ `buildkite-agent`) | `brew tap buildkite/buildkite && brew install buildkite/buildkite/bk` | Yes — pipeline mgmt; agent CLI handles OIDC token requests, signed pipelines, secrets/artifacts | https://buildkite.com/docs/platform/cli |
| 18 | ChatGPT Enterprise | Vendor-Adjacent | OpenAI Codex CLI | `npm i -g @openai/codex` | Partial — Codex workspace toggles, MCP server registration; enterprise admin (Compliance API, SCIM, audit log) is REST-only | https://developers.openai.com/codex/cli |
| 19 | CircleCI | GA-Official | `circleci` | `brew install circleci` | Yes — contexts (secrets), orb signing, OPA policy mgmt, runner tokens | https://circleci.com/docs/guides/toolkit/local-cli/ |
| 20 | Clari | None | — | — | REST API only | https://api-doc.copilot.clari.com/ |
| 21 | Cloudflare | GA-Official (split) | `wrangler`, `cloudflared`, `cf` (new tech preview Apr 2026), `flarectl` (maintenance) | `npm i -g wrangler`; `npm i -g cf` (preview) | Yes — Workers env vars, Zero Trust tunnels/policies, DNS/WAF (flarectl, maintenance mode) | https://developers.cloudflare.com/workers/wrangler/ |
| 22 | SAP Concur | None | — | — | REST API + Joule AI agents | https://help.sap.com/docs/SAP_CONCUR |
| 23 | Coupa | None | — | — | REST API (OAuth2) + flat file integrations | https://compass.coupa.com/ |
| 24 | CrowdStrike | Vendor-Published / Not Officially Supported (toolkit) + sensor-only (falconctl) | `falcon-toolkit` + `falconctl` (endpoint) | `pipx install caracara-cli`; falconctl ships with sensor | falconctl: sensor admin only. Falcon-Toolkit: tenant-wide scripting (NOT a formal product) | https://github.com/CrowdStrike/Falcon-Toolkit |
| 25 | Cursor | GA-Official (Beta) | Cursor CLI / `cursor-agent` | `curl https://cursor.com/install -fsSL \| bash` | No — agent invocation; admin (SSO, audit, MCP allowlist) via dashboard | https://cursor.com/cli |
| 26 | CyberArk Conjur | GA-Official (Conjur only) | `conjur` (`conjur-cli-go`) | `brew tap cyberark/tools && brew install conjur-cli` | Yes — for Conjur Secrets Manager. **NOT for PAS/Privilege Cloud** (which our HTH guide covers) — those use REST API + PowerShell SDK | https://github.com/cyberark/conjur-cli-go |
| 27 | Databricks | GA-Official | `databricks` (Go-based, v0.205+) | `brew tap databricks/tap && brew install databricks` | Yes — workspace, IAM, Unity Catalog, secrets, cluster policies, audit log delivery | https://docs.databricks.com/aws/en/dev-tools/cli/ |
| 28 | Datadog | GA-Official | `datadog-ci` | `npm i -g @datadog/datadog-ci` | Yes (CI hardening) — SBOM upload, SCA, sourcemap upload, secret scanning. Account/RBAC via `datadogpy` SDK | https://github.com/DataDog/datadog-ci |
| 29 | Docker / Docker Hub | GA-Official + Experimental | `docker`, `docker scout`, `docker buildx`, `hub-tool` (experimental) | Docker Desktop / `brew install docker` | Docker CLI: image signing/scout/attestations. Hub admin (orgs, teams, PATs): `hub-tool` is **experimental**; primary path is REST API | https://docs.docker.com/reference/cli/docker/ |
| 30 | DocuSign | None | — | — | Bash + PowerShell code-example launchers (not CLIs); use REST API | https://github.com/docusign/code-examples-bash |
| 31 | Drata | None | — | — | REST API + native integrations | https://developers.drata.com/ |
| 32 | Dropbox | Vendor-Published / Not Officially Supported | `dbxcli` | `go install github.com/dropbox/dbxcli@latest` | Limited — team-admin commands (add/remove members, list groups). Disclaimer: not officially supported | https://github.com/dropbox/dbxcli |
| 33 | Duo (Cisco) | None (SDK with CLI invocation) | `duo_client_python` (Python SDK) | `pip install duo-client` | Yes (via SDK calls) — users, integrations, logs, devices | https://duo.com/docs/adminapi |
| 34 | Figma | Vendor-Adjacent | Code Connect CLI (`figma connect`) | `npm i -g @figma/code-connect` | No — design-system tooling only; admin/SSO via SCIM/REST | https://developers.figma.com/docs/code-connect/ |
| 35 | Fivetran | Vendor-Adjacent | `fivetran` Connector SDK CLI | `pip install fivetran-connector-sdk` | No — custom connector dev only; tenant admin via Terraform provider/REST | https://fivetran.com/docs/connector-sdk/ |
| 36 | Freshservice | Vendor-Adjacent | Freshworks FDK | `npm install https://cdn.freshdev.io/fdk/latest.tgz -g` | No — marketplace app dev only; tenant admin via REST | https://developers.freshworks.com/docs/app-sdk/ |
| 37 | FullStory | None | — | — | REST API + Data Direct | https://developer.fullstory.com/ |
| 38 | GitHub | GA-Official | `gh` (v2.88.1, March 2026) | `brew install gh` | Yes — branch protection, secrets, Dependabot/CodeQL alerts, runners, OIDC, attestation verification, SBOM | https://cli.github.com/ |
| 39 | GitLab | GA-Official | `glab` | `brew install glab` | Yes — protected branches, CI/CD vars, deploy tokens, runner registration, SAST/DAST report retrieval | https://docs.gitlab.com/cli/ |
| 40 | Gong | None | — | — | REST API only | https://help.gong.io/ |
| 41 | Google Workspace | **Vendor-Published / Not Officially Supported** (gws); official CLI announced "coming soon" | `gws` (v0.22.5, Mar 31 2026) | `npm i -g @googleworkspace/cli` or `brew install googleworkspace-cli` | Partial — dynamically-built from Discovery Service. Disclaimer: "not an officially supported Google product"; an official Workspace CLI is coming. **GAM is community-only** | https://github.com/googleworkspace/cli |
| 42 | Gusto | None | — | — | REST API only | https://dev.gusto.com/ |
| 43 | Harness | GA-Official | `harness` (`hcli`) | curl / brew tap | Yes — secrets, connectors, RBAC, OPA governance, delegate registration | https://developer.harness.io/docs/platform/automation/cli/install/ |
| 44 | HashiCorp Vault | GA-Official | `vault` | `brew install hashicorp/tap/vault` | Yes — secrets engines, auth methods (OIDC/JWT/AppRole), policies, audit devices, namespaces, transit/PKI | https://developer.hashicorp.com/vault/docs/commands |
| 45 | Heap | None | — | — | REST API only | https://www.heap.io/ |
| 46 | HubSpot | GA-Official | `hs` (`@hubspot/cli`) | `npm i -g @hubspot/cli` | Partial — auth/PAT, CMS deploy, projects/private apps; no portal SSO/audit ops | https://developers.hubspot.com/docs/developer-tooling/local-development/hubspot-cli/ |
| 47 | Intercom | None | — | — | REST API only (Fin CLI is unrelated AI agent config) | https://developers.intercom.com/ |
| 48 | Jamf | GA-Official | `jamf` (endpoint binary) + Jamf Pro Server Tools CLI | Auto-installed at MDM enrollment; Server Tools via Jamf installer | Yes (endpoint) — `jamf policy`, `jamf recon`, MDM profile, FileVault escrow, EA collection. Server tools: backup/restore | https://learn.jamf.com/en-US/bundle/technical-articles/page/Installing_the_CLI.html |
| 49 | Jenkins | GA-Official | `jenkins-cli.jar` | Download from `<jenkins>/cli` | Limited — job config, credentials, plugins; modern security via JCasC YAML, not CLI | https://www.jinkins.io/doc/book/managing/cli/ |
| 50 | JFrog | GA-Official | `jf` (JFrog CLI v2) | `brew install jfrog-cli` or `curl -fL https://install-cli.jfrog.io \| sh` | Yes — build-info/SBOM publishing, Xray scans, signed evidence/attestations, OIDC token exchange | https://docs.jfrog.com/integrations/docs/jfrog-cli |
| 51 | Jira Cloud | GA-Official | `acli` (Atlassian CLI) | Same as #8 | Same — issue ops, JQL, comments | https://developer.atlassian.com/cloud/acli/ |
| 52 | JumpCloud | PowerShell-Only | `JumpCloud` PowerShell module | `Install-Module JumpCloud` | Yes — user/MFA enforcement, system policies, SSO assignments, Directory Insights audit export | https://jumpcloud.com/support/jumpcloud-powershell-module |
| 53 | Keeper | GA-Official | Keeper Commander + `ksm` | `pip install keepercommander`; `pip install keeper-secrets-manager-cli` | Yes — SSO/SCIM, MFA, role policies, device approvals, IP allowlists, advanced reports | https://docs.keeper.io/en/keeperpam/commander-cli/overview |
| 54 | Klaviyo | GA-Official | Klaviyo CLI (Headless Klaviyo) | `pipx install` (per docs) | Yes (config-as-code) — campaigns, flows, segments, content blocks GET/PUSH | https://developers.klaviyo.com/en/docs/klaviyo_cli |
| 55 | KnowBe4 | None | — | — | REST API only | https://developer.knowbe4.com/ |
| 56 | LastPass | GA-Official (consumer-vault scope) | `lpass` | `brew install lastpass-cli` | **No enterprise admin coverage** — consumer vault only; SSO/MFA/SIEM via Enterprise API | https://github.com/lastpass/lastpass-cli |
| 57 | LaunchDarkly | GA-Official | `ldcli` | `brew install launchdarkly/tap/ldcli` | Yes — flag CRUD, project/env, member/team RBAC, API token mgmt, audit log queries | https://github.com/launchdarkly/ldcli |
| 58 | Linear | None | — | — | GraphQL API only | https://developers.linear.app/ |
| 59 | Looker | Vendor-Published / Not Officially Supported | `gzr` | `gem install gzr` | Yes (limited) — users/groups/roles/content. Disclaimer: not officially supported | https://github.com/looker-open-source/gzr |
| 60 | Mailchimp | None | — | — | REST API only | https://mailchimp.com/developer/ |
| 61 | Marketo (Adobe) | None | — | — | REST API + Marketo MCP Server | https://experienceleague.adobe.com/en/docs/marketo-developer/marketo/mcp-server |
| 62 | Microsoft 365 | PowerShell-Only | `Microsoft.Graph`, `ExchangeOnlineManagement`, `MicrosoftTeams` PowerShell modules | `Install-Module Microsoft.Graph`; `Install-Module ExchangeOnlineManagement`; `Install-Module MicrosoftTeams` | Yes — full M365 admin coverage. **Note: AzureAD/MSOnline retired Oct 2025** | https://learn.microsoft.com/powershell/microsoftgraph/ |
| 63 | Microsoft Entra ID | PowerShell-Only | `Microsoft.Entra` + `Microsoft.Graph` PowerShell + `az ad` | `Install-Module Microsoft.Entra`; `Install-Module Microsoft.Graph`; `brew install azure-cli` | Yes — Conditional Access, MFA, app registrations, PIM, sign-in/audit log export | https://learn.microsoft.com/powershell/entra-powershell/ |
| 64 | Microsoft Intune | PowerShell-Only | `Microsoft.Graph` PowerShell + (legacy) `Microsoft.Graph.Intune` | `Install-Module Microsoft.Graph` | Yes — device enrollment, compliance/configuration policies, app deployment, wipe/retire | https://github.com/microsoft/Intune-PowerShell-SDK |
| 65 | Mimecast | None | — | — | REST API 2.0 + community PowerShell modules | https://integrations.mimecast.com/ |
| 66 | Miro | None | — | — | REST API only | https://developers.miro.com/ |
| 67 | Mixpanel | None | — | — | REST API only | https://docs.mixpanel.com/ |
| 68 | monday.com | Vendor-Adjacent | `mapps` (`@mondaycom/apps-cli`) | `npm i -g @mondaycom/apps-cli` | No — app deploy on monday-code only; admin via GraphQL API | https://developer.monday.com/apps/docs/command-line-interface-cli |
| 69 | MongoDB Atlas | GA-Official | `atlas` CLI | `brew install mongodb-atlas-cli` | Yes — cluster mgmt, network access lists, IAM, backups, audit logs, federated auth | https://www.mongodb.com/docs/atlas/cli/ |
| 70 | Netskope | None | — | — | REST API v2 only | https://docs.netskope.com/ |
| 71 | NetSuite | GA-Official | `suitecloud` (SuiteCloud CLI for Node.js) | `npm i -g --acceptSuiteCloudSDKLicense @oracle/suitecloud-cli` | Yes — SDF deploy/import/validate, role/permission XML, account auth | https://www.npmjs.com/package/@oracle/suitecloud-cli |
| 72 | New Relic | GA-Official | `newrelic-cli` | `brew install newrelic-cli` | Yes — account/user provisioning (NerdGraph), agent install, entity tagging, workload mgmt | https://docs.newrelic.com/docs/new-relic-solutions/build-nr-ui/newrelic-cli/ |
| 73 | Notion | None | — | — | REST API only | https://developers.notion.com/ |
| 74 | Okta | **DEPRECATED (Jul 18, 2025)** + active `okta-aws-cli` | `okta` (deprecated); `okta-aws-cli` (active) | `brew install okta-aws-cli` | okta CLI deprecated; admin hardening via Terraform provider or Management API. okta-aws-cli is for AWS IdP federation only | https://github.com/okta/okta-cli |
| 75 | OneLogin | GA-Official | `onelogin` + `onelogin-aws-cli-assume-role` | `brew tap onelogin/tap-onelogin && brew install onelogin` | Limited — apps, users, mappings, Smart Hooks; many MFA/policy ops still REST-only | https://github.com/onelogin/onelogin |
| 76 | Oracle HCM | None | (HCM Data Loader transfer utility — not a true CLI) | — | API only | https://docs.oracle.com/en/cloud/saas/human-resources/ |
| 77 | Orca Security | None | — | — | REST API + official Terraform provider | https://docs.orcasecurity.com/ |
| 78 | Outreach | None | — | — | REST API + Outreach MCP Server | https://developers.outreach.io/ |
| 79 | PagerDuty | None (community: `pagerduty-cli` by martindstone; `python-pagerduty` includes basic CLI) | — | — | "PagerDuty doesn't support [CLI] officially" | https://github.com/martindstone/pagerduty-cli |
| 80 | Paylocity | None | — | — | REST API (OAuth2) | https://developer.paylocity.com/ |
| 81 | Pendo | None | — | — | REST API + MCP server | https://developers.pendo.io/ |
| 82 | Ping Identity | GA-Official | `pingcli` | `brew install pingidentity/tap/pingcli` | Yes — multi-product config (PingOne, PingFederate); export/import config | https://github.com/pingidentity/pingcli |
| 83 | Postman | GA-Official | Postman CLI + Newman | `brew install --cask postman-cli`; `npm i -g newman` | Yes — collection runs in CI, signed test runs, governance lint, API security checks | https://learning.postman.com/docs/postman-cli/postman-cli-installation |
| 84 | Power BI | PowerShell-Only | `MicrosoftPowerBIMgmt` PowerShell module | `Install-Module MicrosoftPowerBIMgmt` | Yes — tenant admin, workspace admin, audit log export, encryption keys, capacity mgmt | https://learn.microsoft.com/powershell/power-bi/ |
| 85 | Proofpoint | None | — | — | TAP/TRAP/SIEM/Email Protection APIs | https://help.proofpoint.com/ |
| 86 | Qualys | None | — | — | REST/SOAP APIs + community Python SDK | https://qualysguard.qualys.com/qwebhelp/ |
| 87 | Rapid7 | None | — | — | REST API v3 + community Python SDK | https://docs.rapid7.com/ |
| 88 | Rippling | GA-Official (Flux only) | `rippling-cli` | GitHub release / cargo install | No (admin) — Flux integration developer workflow only | https://github.com/Rippling/rippling-cli |
| 89 | SailPoint | GA-Official | `sailpoint-cli` | `brew install sailpoint-cli` | Yes — Identity Security Cloud API, transforms/rules/workflows, search, audit export | https://developer.sailpoint.com/docs/tools/cli/ |
| 90 | Salesforce | GA-Official | `sf` (v66.0 Spring '26) | `npm i -g @salesforce/cli` | Yes — user create, permset assign, profile/permset metadata deploy, ConnectedApp/IpRange/SamlSso metadata | https://developer.salesforce.com/tools/salesforcecli |
| 91 | SAP SuccessFactors | None | — | — | OData API + SAP Cloud SDK | https://help.sap.com/docs/SAP_SUCCESSFACTORS_HXM_SUITE |
| 92 | Segment (Twilio) | None | — | — | Public API SDKs (multi-language) + Terraform provider | https://docs.segmentapis.com/ |
| 93 | SendGrid (Twilio) | Vendor-Adjacent (parent) | `twilio email` (subset of Twilio CLI) | `brew tap twilio/brew && brew install twilio` | Limited — email send via SendGrid; account mgmt via Twilio CLI | https://www.twilio.com/docs/twilio-cli/examples/send-email-sendgrid |
| 94 | Sentry | GA-Official | `sentry-cli` (v3.4.0 Apr 2026) | `brew install sentry-cli` or `npm i @sentry/cli` | Yes — release mgmt, source map/debug file upload, project/org admin, deploy markers | https://docs.sentry.io/cli/ |
| 95 | SentinelOne | Vendor-Adjacent (endpoint only) | `sentinelctl` | Bundled with agent | Endpoint-only — status, scan, config, restart (passphrase-gated). Console admin via REST API | https://www.sentinelone.com/ |
| 96 | ServiceNow | GA-Official | `snc` | Windows installer / ServiceNow Store | Yes — instance ops, app deploy, ATF tests, source control sync, custom component dev | https://www.servicenow.com/docs/r/xanadu/application-development/servicenow-cli/ |
| 97 | Shopify | GA-Official | `shopify` (`@shopify/cli`) | `npm i -g @shopify/cli@latest` | Yes — app/theme dev, store config, webhooks, OAuth scopes | https://shopify.dev/docs/api/shopify-cli |
| 98 | Slack | GA-Official | `slack` (slackapi/slack-cli, v4.0.0 Apr 2026) | `brew install --cask slack-cli` or curl install | App dev focused — manifests, scopes, install/link. **Workspace admin (SSO/audit/DLP) requires Admin & Audit Logs APIs** | https://docs.slack.dev/tools/slack-cli/ |
| 99 | Smartsheet | None (samples only, unmaintained) | `smartsheet-cli` (5+ yrs since release) | — | API only; first-party direction is MCP server | https://github.com/smartsheet-samples/smartsheet-cli |
| 100 | Snowflake | GA-Official | `snow` (Snowflake CLI) | `brew tap snowflakedb/snowflake-cli && brew install snowflake-cli` | Yes — account/warehouse, RBAC, network policies, masking policies, secrets, app deploy. **`snowsql` is being phased out** | https://docs.snowflake.com/en/developer-guide/snowflake-cli/index |
| 101 | Snyk | GA-Official | `snyk` | `npm i -g snyk` | Yes — SCA, container, IaC, code (SAST) scans, SBOM, monitor projects | https://docs.snyk.io/snyk-cli |
| 102 | Splunk | GA-Official | `acs` (Cloud), `splunk` (Enterprise) | `npm i -g @splunk/acs`; bundled with Splunk Enterprise | Yes — HEC token mgmt, IP allowlists, index admin, app install, user/role admin, SSO config | https://help.splunk.com/.../acs-cli |
| 103 | Square | None | — | — | REST API only; community CLIs exist | https://developer.squareup.com/ |
| 104 | Stripe | GA-Official | `stripe` | `brew install stripe/stripe-cli/stripe` | Yes — restricted-key login, webhook listen/forward, event tail, log streams | https://docs.stripe.com/stripe-cli |
| 105 | Tableau | GA-Official | `tabcmd` (2.0 Python rewrite) | `pip install tabcmd` | Yes — user/group/site admin, project mgmt, workbook publish, permissions, PAT auth | https://help.tableau.com/current/online/en-us/tabcmd.htm |
| 106 | Tenable | GA-Official (local) + SDK (cloud) | `nessuscli` (local) + `pyTenable` (SDK) | Bundled with Nessus; `pip install pytenable` | Local Nessus admin via nessuscli; Tenable.io scan/asset mgmt via pyTenable | https://developer.tenable.com/ |
| 107 | Terraform Cloud / HCP | GA-Official | `terraform` + `hcp` | `brew install hashicorp/tap/terraform`; `brew install hashicorp/tap/hcp` | Yes — workspaces, vars, teams, projects, run triggers; OIDC dynamic credentials | https://developer.hashicorp.com/hcp/docs/cli |
| 108 | Twilio | GA-Official | `twilio-cli` (v6.0+) | `brew tap twilio/brew && brew install twilio` | Yes — API key mgmt, subaccount admin, phone-number config, webhook config, plugins | https://www.twilio.com/docs/twilio-cli |
| 109 | UKG | None | — | — | REST API only | https://community.ukg.com/ |
| 110 | Vanta | None | — | — | REST API only | https://developer.vanta.com/ |
| 111 | Vercel | GA-Official | `vercel` | `npm i -g vercel` or `brew install vercel-cli` | Yes — env vars (encrypted), deployment protection, domains/certs, team mgmt | https://vercel.com/docs/cli |
| 112 | Webex | None (general admin) | xCommand UI (Control Hub, room devices); MSI flags (endpoints) | — | No general-purpose admin CLI | https://help.webex.com/en-us/article/9lk0bf/ |
| 113 | Wiz | GA-Official | `wizcli` | `brew install --cask wizcli` | Yes (shift-left) — IaC, container, secrets, SBOM, dir scan. Cloud posture admin via console/API/Terraform | https://www.wiz.io/lp/wiz-cli |
| 114 | Workato | GA-Official | `workato` (Platform CLI) + Connector SDK CLI | `pip install workato-platform-cli` | Yes — project push/pull, recipe lifecycle, OAuth connection mgmt, API client/collection mgmt | https://docs.workato.com/en/platform-cli.html |
| 115 | Workday | Coming GA (announced Jun 2025) | Workday Developer CLI | TBD | Project scaffolding, integration deploy (not yet broadly downloadable) | Workday DevCon 2025 |
| 116 | Zendesk | GA-Official (Beta) | `zcli` | `npm i -g @zendesk/zcli` | App dev/packaging, theme upload, profile/login mgmt | https://developer.zendesk.com/documentation/apps/getting-started/using-zcli/ |
| 117 | Zoom | None | — | — | REST API + MSI flags | https://developers.zoom.us/ |
| 118 | Zscaler | Vendor-Adjacent (SDK + ZPA App Connector local) | `zscaler-sdk-python`, `zpa-api-tool`; ZPA App Connector local CLI | `pip install zscaler-sdk-python` | No general admin CLI; primary path is official Terraform provider | https://help.zscaler.com/ |

---

## Vendors With Existing CLI Packs — Validation Status

The 22 vendor directories with existing `packs/{vendor}/cli/` directories, mapped against verified CLI status:

| Vendor | Existing pack files | Vendor first-party CLI? | Pack is correct? | Action needed |
|--------|--------------------:|-------------------------|------------------|---------------|
| azure-devops | 7 | Yes (`az devops`) | ✅ Yes (uses `az`/PowerShell + pipeline YAML) | Leave as-is |
| bitbucket | 3 | **No first-party CLI** | ❌ No — files are pipeline YAML + git-secrets | **Relocate to `pipelines/`; remove from `cli/`** |
| circleci | 7 | Yes (`circleci`) | ⚠️ Partial — files are `.yml` configs (CircleCI uses YAML); CLI invokes them | Acceptable; consider renaming pack type to `config/` |
| cursor | 12 | Yes (Cursor CLI exists, beta) but packs use bash/jq on local config files | ⚠️ Partial — admin scripts, not Cursor CLI | **Relocate to `scripts/` or `config/`** (no Cursor CLI command is invoked) |
| cyberark | 4 | CyberArk Conjur CLI exists (Vault CLI doesn't) | ❌ No — `.ini` config snippets, NOT CLI invocations + violates extension rules | **Relocate to `config/` and rename extension** |
| databricks | 2 | Yes (`databricks`) | ✅ Yes (uses `databricks` CLI) | Leave as-is |
| dockerhub | 6 | Yes (`docker` + Scout/Buildx) | ✅ Yes (uses `docker scout`, `docker trust`, etc.) | Leave as-is |
| github | 19 | Yes (`gh`) | Mostly YAML workflows + a few `gh` shell scripts | Acceptable mix; `.yml` workflows are GitHub Actions configs, valid here |
| gitlab | 7 | Yes (`glab`) | Mostly YAML pipelines + `git`/`glab` shell scripts | Acceptable |
| google-workspace | 5 | **gws is "not officially supported" by Google**; GAM is community | ⚠️ Existing scripts use **GAM (community-only)** | **Refactor to use `gws` (transparent disclaimer) OR `gcloud` + Admin SDK API** |
| hashicorp-vault | 11 | Yes (`vault`) | ✅ Yes (uses `vault` + `.hcl` config) | Leave as-is |
| jfrog | 4 | Yes (`jf`) | ✅ Yes (uses `jf` + GHA YAML) | Leave as-is |
| microsoft-365 | 7 | Yes (PowerShell modules) | ✅ Yes (.ps1 scripts using Graph/Exchange modules) | Leave as-is |
| microsoft-entra-id | varies | Yes (PowerShell + az ad) | ✅ Yes | Leave as-is |
| microsoft-intune | varies | Yes (PowerShell) | ✅ Yes | Leave as-is |
| okta | 1 | **DEPRECATED Jul 2025**; admin via Terraform/API | ❌ No — `sanitize-har-files.sh` uses pure jq, NOT okta CLI | **Relocate to `scripts/`; do NOT add new okta-CLI packs** |
| ping-identity | varies | Yes (`pingcli`) | ✅ Yes | Leave as-is |
| slack | 1 | Yes (`slack` slack-cli) but slack-cli is app-dev focused | ❌ No — `.regex` data file, NOT CLI invocation + violates extension rules | **Delete or convert to API-based script** |
| snowflake | varies | Yes (`snow`) | ✅ Yes | Leave as-is; consider migrating any `snowsql` references to `snow` |
| vercel | varies | Yes (`vercel`) | ✅ Yes | Leave as-is |
| wiz | varies | Yes (`wizcli`) | ✅ Yes | Leave as-is |
| workato | 3 | Yes (`workato` Platform CLI + Connector SDK CLI) | ⚠️ Mixed — `7.03-workato-cli.sh` valid; `4.03-deploy-opa.sh` uses `docker` not `workato`; `4.03-agent-config.sh` is comments-only | **Clean up: split docker-based deploy to `scripts/`; remove comments-only file; keep valid `workato-cli.sh`** |

---

## Priority Corrective Actions (Driven by Verified Inventory)

### Tier 1 — Forbidden extensions (CLAUDE.md violations, must fix)
1. `packs/cyberark/cli/*.ini` (4 files) — `.ini` is forbidden
2. `packs/slack/cli/*.regex` (1 file) — `.regex` is forbidden

### Tier 2 — Non-CLI content in cli/ directory
3. `packs/bitbucket/cli/*` (3 files) — Bitbucket has no first-party CLI; content is Pipelines YAML + git-secrets
4. `packs/cursor/cli/*` (12 files) — bash scripts editing local Cursor config files; no Cursor CLI invocation
5. `packs/okta/cli/hth-okta-7.01-sanitize-har-files.sh` — pure jq script
6. `packs/workato/cli/hth-workato-4.03-agent-config.sh` — comments only, no executable code
7. `packs/workato/cli/hth-workato-4.03-deploy-opa.sh` — uses `docker`, not `workato`

### Tier 3 — Third-party tool dependence
8. `packs/google-workspace/cli/*` (5 files) — Use **GAM** which is community/non-Google. Refactor to `gws` (vendor-published, with disclaimer) or `gcloud` + Admin SDK API.

---

## Open Questions for Future Work

- **`gws` adoption decision:** Should we accept Google's "not officially supported" CLI and add a header disclaimer, OR wait for the announced "official" Workspace CLI?
- **Okta direction:** With the official `okta` CLI deprecated, future Okta hardening packs should target Terraform provider or REST API curl scripts.
- **Bitbucket/Atlassian:** Atlassian's `acli` does not currently cover Bitbucket. Watch for future expansion.
- **Cursor:** New `cursor-agent` CLI is in beta and primarily for agent invocation, not config admin. Existing scripts that touch `settings.json`/`mcp.json` directly remain the practical hardening surface.
- **CircleCI/GitLab/GitHub `.yml` files:** These represent CI configuration consumed *by* the platform — they are not invoked as CLI commands directly. Consider whether `cli/` is the right pack-type label, or if a `pipelines/` type would be more accurate.
