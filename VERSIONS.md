# HTH Guide Versions

This document provides a central registry of all How to Harden (HTH) guides with their current version and maturity status.

## Versioning Model

HTH uses **Extended SemVer with Maturity Qualifier**:

```
v{MAJOR}.{MINOR}.{PATCH}-{maturity}
```

### Semantic Version Components

| Component | Increment When... | Examples |
|-----------|-------------------|----------|
| **MAJOR** | Breaking changes, removed controls, major restructuring | Control removed, guide reorganized |
| **MINOR** | New controls, new sections, significant enhancements | New L1/L2/L3 control added |
| **PATCH** | Fixes, clarifications, typos, minor updates | Typo fix, URL update, wording clarification |

### Maturity Qualifiers

| Qualifier | Meaning | Criteria |
|-----------|---------|----------|
| `draft` | AI-generated or unreviewed contribution | Initial AI-assisted creation, unvalidated updates |
| `reviewed` | Expert review complete | SME has validated accuracy of all controls |
| `verified` | Tested in real environment | Controls tested and validated in production |

### Version Examples

- `v0.1.0-draft` - Initial AI-drafted guide
- `v0.1.1-draft` - AI-drafted with typo fixes
- `v0.2.0-reviewed` - Human-reviewed with new control added
- `v1.0.0-verified` - First verified release, production-tested

### Author Attribution

Changelog entries must attribute authors accurately:

| Author Type | Format | Example |
|-------------|--------|---------|
| Human contributor | GitHub handle or name | `@username`, `Jane Doe` |
| Claude Code | `Claude Code ({model})` | `Claude Code (Opus 4.5)` |
| Other AI tools | `{Tool Name} ({model})` | `GitHub Copilot (GPT-4)` |
| Community (legacy) | `How to Harden Community` | For pre-versioning entries |

---

## Guide Version Registry

Last updated: 2025-12-27

### Tier 1 (High Priority)

| Guide | Version | Maturity | Last Updated |
|-------|---------|----------|--------------|
| [Okta](docs/_guides/okta.md) | v0.2.0 | draft | 2025-12-26 |
| [GitHub](docs/_guides/github.md) | v0.1.0 | draft | 2025-12-13 |
| [Salesforce](docs/_guides/salesforce.md) | v0.1.0 | draft | 2025-12-13 |
| [Snowflake](docs/_guides/snowflake.md) | v0.1.0 | draft | 2025-12-13 |
| [Workday](docs/_guides/workday.md) | v0.1.0 | draft | 2025-12-13 |
| [ServiceNow](docs/_guides/servicenow.md) | v0.1.0 | draft | 2025-12-13 |
| [Atlassian](docs/_guides/atlassian.md) | v0.1.0 | draft | 2025-12-13 |
| [Datadog](docs/_guides/datadog.md) | v0.1.0 | draft | 2025-12-13 |
| [CrowdStrike](docs/_guides/crowdstrike.md) | v0.1.0 | draft | 2025-12-13 |

### Tier 2

| Guide | Version | Maturity | Last Updated |
|-------|---------|----------|--------------|
| [Azure DevOps](docs/_guides/azure-devops.md) | v0.1.0 | draft | 2025-12-13 |
| [Terraform Cloud](docs/_guides/terraform-cloud.md) | v0.1.0 | draft | 2025-12-13 |
| [GitLab](docs/_guides/gitlab.md) | v0.1.0 | draft | 2025-12-13 |
| [CircleCI](docs/_guides/circleci.md) | v0.1.0 | draft | 2025-12-13 |
| [HashiCorp Vault](docs/_guides/hashicorp-vault.md) | v0.1.0 | draft | 2025-12-13 |
| [Databricks](docs/_guides/databricks.md) | v0.1.0 | draft | 2025-12-13 |
| [Splunk](docs/_guides/splunk.md) | v0.1.0 | draft | 2025-12-13 |
| [NetSuite](docs/_guides/netsuite.md) | v0.1.0 | draft | 2025-12-13 |
| [ADP](docs/_guides/adp.md) | v0.1.0 | draft | 2025-12-13 |
| [DockerHub](docs/_guides/dockerhub.md) | v0.1.0 | draft | 2025-12-13 |
| [JFrog](docs/_guides/jfrog.md) | v0.1.0 | draft | 2025-12-13 |
| [Snyk](docs/_guides/snyk.md) | v0.1.0 | draft | 2025-12-13 |
| [Zoom](docs/_guides/zoom.md) | v0.1.0 | draft | 2025-12-13 |

### Tier 3

| Guide | Version | Maturity | Last Updated |
|-------|---------|----------|--------------|
| [Ping Identity](docs/_guides/ping-identity.md) | v0.1.0 | draft | 2025-12-13 |
| [SailPoint](docs/_guides/sailpoint.md) | v0.1.0 | draft | 2025-12-13 |
| [CyberArk](docs/_guides/cyberark.md) | v0.1.0 | draft | 2025-12-13 |
| [BeyondTrust](docs/_guides/beyondtrust.md) | v0.1.0 | draft | 2025-12-13 |
| [HubSpot](docs/_guides/hubspot.md) | v0.1.0 | draft | 2025-12-13 |
| [Zendesk](docs/_guides/zendesk.md) | v0.1.0 | draft | 2025-12-13 |
| [Freshservice](docs/_guides/freshservice.md) | v0.1.0 | draft | 2025-12-13 |
| [Box](docs/_guides/box.md) | v0.1.0 | draft | 2025-12-13 |
| [Dropbox](docs/_guides/dropbox.md) | v0.1.0 | draft | 2025-12-13 |
| [Looker](docs/_guides/looker.md) | v0.1.0 | draft | 2025-12-13 |

### Tier 4

| Guide | Version | Maturity | Last Updated |
|-------|---------|----------|--------------|
| [Tableau](docs/_guides/tableau.md) | v0.1.0 | draft | 2025-12-13 |
| [Power BI](docs/_guides/power-bi.md) | v0.1.0 | draft | 2025-12-13 |
| [Notion](docs/_guides/notion.md) | v0.1.0 | draft | 2025-12-13 |
| [Asana](docs/_guides/asana.md) | v0.1.0 | draft | 2025-12-13 |
| [Monday](docs/_guides/monday.md) | v0.1.0 | draft | 2025-12-13 |
| [Miro](docs/_guides/miro.md) | v0.1.0 | draft | 2025-12-13 |
| [Smartsheet](docs/_guides/smartsheet.md) | v0.1.0 | draft | 2025-12-13 |
| [PagerDuty](docs/_guides/pagerduty.md) | v0.1.0 | draft | 2025-12-13 |
| [New Relic](docs/_guides/new-relic.md) | v0.1.0 | draft | 2025-12-13 |
| [Wiz](docs/_guides/wiz.md) | v0.1.0 | draft | 2025-12-13 |

### Tier 5

| Guide | Version | Maturity | Last Updated |
|-------|---------|----------|--------------|
| [SAP SuccessFactors](docs/_guides/sap-successfactors.md) | v0.1.0 | draft | 2025-12-13 |
| [Oracle HCM](docs/_guides/oracle-hcm.md) | v0.1.0 | draft | 2025-12-13 |
| [BambooHR](docs/_guides/bamboohr.md) | v0.1.0 | draft | 2025-12-13 |
| [Gusto](docs/_guides/gusto.md) | v0.1.0 | draft | 2025-12-13 |
| [Rippling](docs/_guides/rippling.md) | v0.1.0 | draft | 2025-12-13 |
| [Marketo](docs/_guides/marketo.md) | v0.1.0 | draft | 2025-12-13 |
| [Klaviyo](docs/_guides/klaviyo.md) | v0.1.0 | draft | 2025-12-13 |
| [Mailchimp](docs/_guides/mailchimp.md) | v0.1.0 | draft | 2025-12-13 |
| [LaunchDarkly](docs/_guides/launchdarkly.md) | v0.1.0 | draft | 2025-12-13 |
| [Vercel](docs/_guides/vercel.md) | v0.1.0 | draft | 2025-12-13 |

### Other

| Guide | Version | Maturity | Last Updated |
|-------|---------|----------|--------------|
| [Cursor](docs/_guides/cursor.md) | v0.1.0 | draft | 2025-12-15 |

---

## Version History Summary

| Milestone | Date | Description |
|-----------|------|-------------|
| Versioning model introduced | 2025-12-27 | Extended SemVer with maturity qualifiers adopted |
| Initial guides created | 2025-12-13 | 53 AI-drafted guides published |

---

## Notes

- **Pre-1.0 versions**: All guides start at `v0.x.x` during the alpha phase. Version `v1.0.0` is reserved for guides that have achieved `verified` maturity status.
- **Maturity progression**: A guide can advance in maturity without content changes (e.g., `v0.1.0-draft` → `v0.1.0-reviewed`), or content can change while maintaining maturity level (e.g., `v0.1.0-reviewed` → `v0.2.0-reviewed`).
- **Registry updates**: This file should be updated whenever a guide version changes.
