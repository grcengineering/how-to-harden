# Initial source coverage for Egnyte, Files.com, ShareFile and Tresorit

Reviewed November 27, 2026 against the linked public first-party materials. These are scoped starting guides, not a complete vendor baseline, tenant attestation, or evidence of product availability on the same plan.

| Product | Covered and candidate controls | Disposition |
|---------|--------------------------------|-------------|
| Egnyte | [Administrator index](https://helpdesk.egnyte.com/hc/en-us/articles/360028823372-Administrator-Settings), SSO assignments, links, and audit streams. | Hybrid storage, client mass deployment, EKM and retention policy require separate research; inherited share settings are not assumed. |
| Files.com | [Identity and access](https://www.files.com/compliance/identity-and-access/authentication-and-access-configuration), interactive MFA, transfer identities and bearer link controls. | Hub product only, not ExaVault, Mover or ExpanDrive. Site-level options, workspace and parent-site inheritance require readback. |
| ShareFile | [Admin guide](https://docs.sharefile.com/en-us/sharefile/get-started/sharefile-admin-guide), MFA, employee roster, signed-in links, Enterprise/VDR Security Center. | Mobile security, ShareFile for Windows policy definitions and customer storage zones are separate control planes. MFA-enabled is not automatically MFA-required. |
| Tresorit | [Admin Center](https://support.tresorit.com/hc/en-us/articles/360000980474-Introduction-to-Admin-Center), subscription roles, sharing/device policies and Sentinel. | Advanced Control is an explicit key/access governance decision. S3-compatible API and Linux CLI are not general tenant administration. |

## Automation census

| Surface | Egnyte | Files.com | ShareFile | Tresorit |
|---------|--------|-----------|-----------|----------|
| REST/GraphQL | SCIM-style user inventory and audit read packed; user/link writes documented but not packaged. No admin GraphQL claim. | Documented user read packed; [API key API](https://developers.files.com/rest/resources/developers/api-keys/) is separate. No admin GraphQL claim. | Read-only OData employee identifiers packed for .com endpoint. No security policy or sharing default write claimed, and no GraphQL handler verified. | [S3-compatible API](https://support.tresorit.com/hc/en-us/articles/33971802915858-Tresorit-API) is a local storage interface, not an admin API. Tenant policy HTTP/GraphQL unverified. |
| CLI | First-party CLI user list packed. No automation that invokes agents. | First-party user detail command packed. | Current vendor PowerShell module is packaged as the first-party PowerShell surface; no legacy SFCLI. | Linux local-client status packed. |
| SDK | Doc examples verified; no separate production SDK pack. | Vendor SDK references exist; no separate SDK pack in this initial slice. | The same official PowerShell module uses the documented OData request; explicit .NET runtime requirements in vendor docs. | S3-compatible transport tools do not imply subscription policy administration. |
| Terraform/config | No supported policy provider identified in the reviewed public references. | [First-party Terraform reference](https://developers.files.com/terraform/resources/user-accounts/sso-strategies/) includes SSO strategies. No generic tenant writes packaged. | Windows client GPO is documented; no separate hosted tenant provider verified. | No supported subscription policy provider or native config file verified. |
| SIEM | Audit v2 continuity checked, not a query for a specific ingest pipeline. | Logging and export reference exists; no query without reviewed ingestion schema. | Security Center UI and API reporting categories are not proof of a supported detection schema. | Business Pro/Enterprise Sentinel feed packed as a read-only KQL summary for documented schema. |

The bounded public-source sweep did not establish a directly applicable named benchmark for these product editions. No private Trust Center material or production evidence was reviewed. Public trust attestations were not used as instructions for configuring customer policy.
