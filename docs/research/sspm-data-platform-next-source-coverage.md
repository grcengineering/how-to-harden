# Anaplan, Adobe Workfront, Qualtrics XM and Domo starter scope

Discovery snapshot: November 27, 2026. Starter controls map to the named
customer tenancy planes. No tenant or real evidence was used.

| Product | Verified source planes | Coverage boundary |
|---------|------------------------|-------------------|
| Anaplan | Anapedia tenant IP allowlist and covered client matrix; tenant roles and model access; Audit entitlement, exact GET route and authentication; Anaplan Connect | The 24-hour Audit sample is limited to one page of up to 20 records and omits direct actor, source IP and payload details. Review protected raw evidence in the UI. SAML setup, SCIM, model role administration automation, tenant API endpoint parity and BYOK implementation were not established for this guide. Anaplan Connect is for integration actions, not assumed admin policy coverage. |
| Adobe Workfront | Workfront Admin Console administration, access level and Audit Logs help; Adobe Developer Console migration and technical account docs; Adobe UMAPI user read and OAuth Server-to-Server authentication | UMAPI evidence concerns one Adobe organization identity, not effective Workfront ACLs. Workfront Core, Planning, Fusion and MCP are different API families. No Workfront tenant audit API for the exact UI event stream was established. Adobe shared admin and Workfront-specific controls do not imply coverage of other Adobe product editions. |
| Qualtrics XM | Qualtrics organization authentication settings, Security tab and first-party Users API | One read returns declared tenant, division and expiry fields. It does not resolve the user type's full permissions, respondent policy, or test MFA. The vendor documents an enterprise audit API separately; no coverage or connector writes are claimed by the single user read. |
| Domo | Governance People and Activity Log, API Clients and Domo DataFlow/PDP documentation; first-party Domo SDK Users endpoint and transport | One scoped Users API GET does not infer group-derived, custom grants or PDP. The public interactive API docs were blocked for unauthenticated inspection; first-party SDK source and Domo's published endpoint slides provide the read contract. Customer-authenticated API scope and returned roles still require live validation. |

Public vendor configuration and developer references were admitted as evidence;
assurance-only material was not treated as proof of a customer setting. No exact
CIS benchmark was identified by a bounded search of the
[public catalog](https://www.cisecurity.org/cis-benchmarks). DISA, SCuBA, NSA,
ACSC and private vendor-trust-center baselines remain unverified for these
products. First-party CLI coverage is individually bounded in the CLI
inventory. Vendor Terraform provider, other SDK and SIEM implementation
coverage is not claimed by these starter guides.

Offline verification covers source shape, Bash syntax, static shell analysis,
successful response filtering and fail-closed handling of missing inputs or
unmatched responses. Runtime permission, licensed feature, exact account
configuration and effective control verification require an authorized tenant.
