# Slack OAuth token rotation: bounded reconciliation

Checked 2026-11-14 against main `5e9504e`. This is a narrow addition, not a full Slack currency audit. Public first-party documents were fetched and their relevant bodies read through web retrieval. No tenant, app credential or live setting was accessed. Guide maturity remains ai-drafted.

## Source-first findings

| Candidate/source | Observation | Disposition |
|---|---|---|
| [Organization app policies](https://slack.com/help/articles/360038559694-Set-organization-level-policies-for-apps) | Enterprise token-rotation requirement applies prospectively to installs/updates; unused refresh tokens expire after 30 days | New 3.4, with existing-app reconciliation |
| [Token rotation](https://docs.slack.dev/authentication/using-token-rotation/) | 12-hour OAuth access tokens; test refresh before irreversible app enablement | 3.4 prerequisites; no post-breach rotation procedure |
| [App lifecycle](https://docs.slack.dev/app-management/distribution/) | Manifest rotation setting affects newly issued tokens | Validation must not equate manifest state with all tokens migrated |
| [Manifest schema](https://docs.slack.dev/reference/app-manifest/) | OAuth and app-level token rotation are separate properties | OAuth config fragment only; app-level coverage remains follow-up |
| [Manifest export](https://docs.slack.dev/reference/methods/apps.manifest.export/) | Configuration-token read for an authorized app, not arbitrary third-party inventory | Fail-closed 3.4 API read |
| [CLI manifest](https://docs.slack.dev/tools/slack-cli/reference/commands/slack_manifest/) | Remote and local sources differ | Explicit remote-source CLI read; no local posture assertion |

## Automation census for this control

| Surface | Write/read evidence and decision |
|---|---|
| Terraform | No resource/data-source census completed for the org policy; unverified, no provider or resource invented |
| REST / GraphQL | Documented app-manifest export used for read. Org policy write/read and GraphQL contract unverified. App manifest writes exist but deployment is deliberately left to reviewed complete-manifest workflow, not an unsafe fragment replacement |
| First-party CLI | Inventory lists Slack CLI as app-development focused. Current command reference verifies remote manifest read. Included; not an organization admin-policy setter |
| SDK | Export reference lists official language wrappers of same app-manifest operation. No additional policy coverage established; API pack supplies the read without adding a dependency or duplicate SDK wrapper |
| Config | Native YAML settings.token_rotation_enabled fragment for owned apps; not standalone full manifest or organization policy |
| SIEM | Existing audit export coverage retained; no rotation-policy event schema verified, so no invented event/detection |

All used handles are present in current documentation without a deprecation label in the checked sections. Offline tests exercise failure paths and request boundaries, not Slack enforcement. Read packs cannot prove token expiry, app refresh correctness, or third-party coverage.

## Trust Center boundary and adjacent baseline

Followed [Slack Trust Center](https://slack.com/trust) to Security and [Compliance](https://slack.com/trust/compliance). Security redirected to localized Japanese content; no configuration claim depends on it. Compliance's public resource list linked the [Secure Configuration Guide for FedRAMP Moderate](https://a.slack-edge.com/0962f19/marketing/downloads/compliance/Slack-Secure-Configuration-Guide-FedRAMP-Moderate.pdf), whose five-page body was read (version 0.02, 2026-02-24). No paginated document catalog was exposed in the inspected public list; this is not a claim of complete Salesforce/Slack catalog coverage. HIPAA requirements and IRAP report requests were not submitted; restricted customer responsibility matrix remains unread.

The PDF applies to Enterprise/Enterprise+ FedRAMP Moderate, not GovSlack High or every commercial tenant. Its SSO/MFA, app approval, audit, session and EKM themes overlap existing guide sections. EMM/file-download restrictions, system-use banner, invitation/domain controls and unsupported-client monitoring are follow-up candidates requiring current product references and a broader pass. Do not transplant regulatory applicability. This addition resolves OAuth rotation only; those candidates remain explicit backlog.

Publication review additionally disabled local curl configuration, applied runtime profile gates, and wired the offline Slack/Snowflake tests into the existing CI workflow. Primary source bodies were independently fetched again before publication.
