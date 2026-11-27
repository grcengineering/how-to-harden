# Fleet Cloud and Gainsight CS source coverage

Reviewed 2026-11-27. The coverage set is the published customer-controlled cloud product, not adjacent products, Fleet server internals, or the Salesforce receiver. No customer environment was accessed. Suggested mappings document control intent, not formal compliance.

| Product | Source candidate | Disposition |
|---------|------------------|-------------|
| Fleet Cloud | [SAML and JIT provisioning](https://fleetdm.com/docs/deploy/single-sign-on-sso) | Covered for administrative SSO, avoiding premature JIT role grants, and recovery. Employee device sign-in is separate. |
| Fleet Cloud | [RBAC](https://fleetdm.com/guides/role-based-access) and [API-only users](https://fleetdm.com/guides/fleetctl#using-fleetctl-with-an-api-only-user) | Covered for fleet-level and global operator roles, non-expiring API-only credentials and endpoint restrictions. |
| Fleet Cloud | [REST API](https://fleetdm.com/docs/api/rest-api) and [fleetctl](https://fleetdm.com/guides/fleetctl) | Verification via SSO and activity REST reads and fleetctl role export. Organization-level settings can use documented [GitOps YAML](https://fleetdm.com/docs/configuration/yaml-files), with the existing configuration and an approved change; no blanket apply pack. |
| Fleet Cloud | [Global audit logs](https://fleetdm.com/docs/api/global-audit-logs) and [server configuration](https://fleetdm.com/docs/configuration/fleet-server-configuration) | Covered as configuration assessment and bounded event sampling. Hosting-level logging flags are explicitly outside Fleet Cloud tenant scope. |
| Gainsight CS | [User Management](https://support.gainsight.com/gainsight_nxt/User_Management) and [User Management APIs](https://support.gainsight.com/docs/user-management-apis-1) | Covered for SSO, privileged user inventory and role review. Fetch User Details is read-only despite POST; user-write API does not set Super Admin. |
| Gainsight CS | [Trusted IP ranges](https://support.gainsight.com/gainsight_nxt/01Onboarding_and_Implementation/Onboarding_for_Gainsight_NXT/Login_and_Permissions/Allow_List_Trusted_IP_Addresses) and [OAuth](https://support.gainsight.com/v1/docs/oauth-for-gainsight-apis) | Covered for application vs connector controls, mobile exceptions and connector credentials; no verified write handle for allowlists. Salesforce-side access is distinct. |
| Gainsight CS | [Vendor technical incident analysis](https://www.gainsight.com/blog/how-we-accelerated-a-year-of-security-work-in-weeks/) | Motivation for reviewing and limiting long-lived OAuth grants and independently reviewing relying-party policies, not a claim all customers were affected. |

### Automation boundaries

| Surface | Fleet Cloud | Gainsight CS |
|---------|-------------|-------------|
| REST | Verified app SSO and bounded global activity reads. | Verified user-record list, documented separate user changes. |
| CLI | First-party fleetctl role export and tenant administration. | No first-party admin handle verified in the public reference reviewed. |
| Terraform | Management-plane provider unverified. | Tenant administration provider unverified. |
| SDK | Separate official admin SDK handle unverified. | Official admin SDK handle unverified. |
| Native config | Documented GitOps customer settings. Server daemon configuration applies to self-managed deployments only. | Native customer-admin policy config unverified. |
| SIEM | Global activity schema is available; sink-specific event coverage must be verified. | User-record history in UI only in reviewed sources; an organization-wide export contract was not verified. |

The reviewed public product and API docs did not establish a product-specific CIS, STIG, SCuBA or vendor benchmark. The guide uses NIST SP 800-53 Rev. 5 mappings instead. Vendor security and hosting claims do not substitute for documented customer settings.
