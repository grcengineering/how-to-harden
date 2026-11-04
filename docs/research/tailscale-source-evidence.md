# Tailscale source and automation evidence

Research date: **2026-11-04 UTC**. Subject: core Tailscale tailnet administration; eighteen controls and 27 packs. **No tenants declared — Tier 0+1 only.** Every control is documentation-level `DRIFT-CHECKED-ONLY`; `VERIFIED-LIVE = 0`. This source ledger is not a product test result.

## Placement and scope

Tailscale Inc. / Tailscale US Inc. → standalone Tailscale → core tailnet controls. The [current terms](https://tailscale.com/terms), fetched in this run, name the contracting entities by account population. Official-site searches across the last ~24 months did not identify a completed change of control requiring another platform placement. No other Tailscale product guide or owner platform existed in the fetched HTH main branch. PAM and Aperture have distinct surfaces and are explicitly outside this guide. Generic cloud/router/OS hardening and secret rotation are excluded.

## Source sweep

| Tier / area | Result and limits |
|-------------|-------------------|
| Tier 1 | Current admin configuration docs fetched for identity, membership, devices, policy, tags, SSH, posture, automation, routes, sharing, Funnel, updates and logging. Exact control citations follow below. Trust/marketing pages were not used to originate controls. |
| CIS Benchmark | Product-targeted official-domain/index searches did not identify a Tailscale benchmark. This is not a proof of universal absence. [CIS Controls v8](https://www.cisecurity.org/controls/v8) was fetched for family context; no product-specific safeguard numbering is claimed. |
| CISA SCuBA | Current project/official-domain searches did not identify Tailscale coverage; no SCuBA policy ID is asserted. |
| DISA | Public index coverage could not be established. Recorded as unverified, not as no STIG. |
| NSA / ACSC | Official-domain product searches did not identify a Tailscale configuration baseline. |
| Tier 2b | [NIST SP 800-53 Rev. 5](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final) fetched for stable control/family context. Mappings describe support, not sufficiency or certification. |
| Tier 3/4 | Searches of standing research sources including Datadog Security Labs, Wiz, Unit 42, Trail of Bits, Google Threat Intelligence, Dirk-jan Mollema, Embrace The Red and Krebs did not produce a qualifying recent Tailscale-specific configuration finding used here. No speculative incident narrative was added. |
| Vendor security events | [Security bulletins](https://tailscale.com/security-bulletins) fetched; used to support monitoring/patch-currency workflow. No claim that an individual control would certainly have prevented a historical incident. |

## Six-surface census

All shipped handles have status **available** in the fetched references; no beta, removed or deprecated handle is knowingly used. The old Go client is **unmaintained**, so it is not imported. The legacy array posture syntax remains supported but the new pack uses the recommended object syntax. The public reference does not identify a GraphQL admin API; no GraphQL endpoint or schema was invented.

| Surface | Verified first-party index / handles | Write/read decision |
|---------|--------------------------------------|---------------------|
| Terraform | [Official source documentation index](https://github.com/tailscale/terraform-provider-tailscale/tree/v0.29.3/docs), complete resource/data list enumerated below; [release 0.29.3](https://github.com/tailscale/terraform-provider-tailscale/releases/tag/v0.29.3). Registry frontend fetch did not yield reference content, so the first-party source docs were used. | Six packs cover real resources and read data sources. No resources or inventory reads by default; no credential creation. Provider binary/schema execution remains separately reported. |
| REST | [API index](https://tailscale.com/docs/reference/tailscale-api), [scope-to-endpoint matrix](https://tailscale.com/docs/reference/trust-credentials), and official SDK request construction. The interactive API page is a JS shell to the web text fetcher, so exact request/response details were checked against the published client source and specific log docs. | Eleven read/evaluation packs. POST is limited to candidate validation; policy apply is deliberately absent. |
| CLI | [First-party tailscale reference](https://tailscale.com/docs/reference/tailscale-cli), [Funnel command](https://tailscale.com/docs/reference/tailscale-cli/funnel), Lock reference; cli-inventory row 129 added. | Three local read packs. Client mutation commands are documented but are not executed or wrapped as automatic host changes. |
| SDK | [Maintained official v2 SDK](https://github.com/tailscale/tailscale-client-go-v2), [release 2.12.0](https://github.com/tailscale/tailscale-client-go-v2/releases/tag/v2.12.0); older implementation README explicitly points to the replacement. | One real device-read pack. Other documented equivalents are listed below; REST is used for the other shipped collection workflows. No credential creation or typed policy round-trip. |
| Native config | [Policy syntax](https://tailscale.com/docs/reference/syntax/policy-file), [grants](https://tailscale.com/docs/reference/syntax/grants), posture and SSH references. | One local complete-candidate generator plus four fragments. No application/deployment operation. |
| SIEM | [Documented configuration JSON](https://tailscale.com/docs/features/logging/audit-logging), [log streaming](https://tailscale.com/docs/features/logging/log-streaming). | One customer-resident SPL investigation query. Local index/sourcetype names are explicit assumptions, not fabricated vendor SQL tables. |

Coverage: **17/18 controls** have an included pack; **six distinct surfaces** are shipped. The remaining manual control is upstream MFA (1.1), with an evidenced verdict. Read scripts collect evidence rather than declaring compliance. Console-only parts and narrower collection scopes are stated in each guide control and the pack README. The matrix below enumerates exposed interfaces, including interfaces intentionally not wrapped; it does not assert that every possible API/SDK mutation has a pack.

## Per-control interface matrix

| Control | Terraform | REST | CLI | SDK | Native config | SIEM / evidence |
|---------|-----------|------|-----|-----|---------------|-----------------|
| 1.1 Require Phishing-Resistant MFA at the IdP | None: upstream IdP | None: upstream IdP | None: upstream IdP | None: upstream IdP | None: upstream IdP | None |
| 1.2 Govern Membership, Roles and Offboarding | users/user data sources | GET /tailnet/{tailnet}/users; user lifecycle endpoints | None for central membership | Users.List | Policy groups; SCIM is IdP-managed | Configuration events |
| 1.3 Review New Device Enrollment | tailnet_settings; device_authorization | GET/PATCH settings; device authorized endpoint | Local enrollment; no central approval setting | TailnetSettings.Get/Update; Devices.SetAuthorized | Enrollment is not a policy fragment | Approval/configuration events |
| 1.4 Review Node Key Expiry and Exceptions | devices/device data; device_key; tailnet_settings | GET devices; device key endpoint; settings | Local reauthentication (not shipped) | Devices.List/Get/SetKey | Tag authentication changes expiry default | Expiry/configuration events |
| 1.5 Evaluate Tailnet Lock with a Recovery Plan | None in full provider index | No Lock management endpoint in public scope census | lock status and documented signing/initialization commands | No central Lock API handle found | No policy toggle for Lock | Lock configuration events |
| 2.1 Replace Broad Allows with Least-Privilege Grants | acl resource + data source | GET/POST /acl; preview/validate | GitOps integrations; no generic client policy-apply command | PolicyFile.Raw/Get/Set; typed ACL has schema gaps | Complete HuJSON grants/acls | Policy configuration events |
| 2.2 Test Policy Changes Before Deployment | acl planning validation | POST /acl/validate; preview | No generic client policy-validator command | PolicyFile.Validate | tests, sshTests, srcPostureAttrs | Policy update events (not a test runner) |
| 2.3 Constrain Tag Ownership and Workload Identity | acl; device_tags; devices data | Policy; device tags; credential metadata | Tagged client enrollment | PolicyFile; Devices.SetTags | tagOwners; identity and tag union | Tag/policy events |
| 2.4 Restrict Tailscale SSH and Require Reauthentication | acl; devices data | Policy; devices fields=all SSH metadata | set --ssh (host mutation not shipped) | PolicyFile; Devices.GetWithAllFields | ssh, sshTests, network grants | Configuration; separate session recording |
| 2.5 Require Posture on Sensitive Access Rules | acl; posture_integration | Device attributes; posture status in devices | Client report-posture preference | DevicePosture; device attributes; typed posture gap | Object assertions, srcPosture, tests | Posture/configuration events |
| 3.1 Scope Automation Trust Credentials | oauth_client; federated_identity (not shipped: no credential creation) | Known-ID GET /keys/{id}; trust scopes | No credential-admin client command | Keys.Get and credential lifecycle methods | Credential tag authority references tagOwners | Credential configuration events |
| 3.2 Limit CI and Third-Party Workload Enrollment | tailnet_key (not shipped: no credential creation); acl | GET keys + known-ID metadata; auth-key creation not shipped | Client auth-key enrollment (not shipped) | Keys.List/Get; Devices.List | Workload grants, tagOwners and negative tests | Enrollment/configuration events |
| 3.3 Review Subnet and Exit-Node Routes | device_subnet_routes; devices data; acl | Devices and per-device routes | advertise-routes/exit-node preferences (not shipped) | Devices routes methods | autoApprovers, routed-destination grants | Route events and entitled flow logs |
| 4.1 Govern External Sharing and Tailnet Membership | tailnet_settings external joining role; devices data | External-device flag; settings; separate invite surfaces | No full outbound-recipient inventory client command | Devices.List; settings | Identity grants; sharing/posture caveats | Sharing/invite/configuration events |
| 4.2 Prevent Unapproved Public Funnel Exposure | acl for nodeAttrs | Full policy read/write | funnel status; enable/reset are mutating and not shipped | PolicyFile.Raw; no local Funnel admin SDK pack | funnel nodeAttrs, reviewed complete policy | Policy changes; node publication still needs local review |
| 4.3 Maintain Supported Clients and Security Contacts | tailnet_settings; devices data; contacts | Settings/devices/contacts | version; update/set preferences (writes not shipped) | Devices.List; settings; contacts | Optional posture conditions, not patch installation | Configuration; security bulletins separately |
| 5.1 Retain and Review Configuration Audit Logs | logstream_configuration; no log-history data source | GET logging/configuration; status/stream endpoints | No central audit-export client command | Logging stream configuration; REST used for audit export | No native log-query database | Documented JSON -> customer SPL |
| 5.2 Export Flow Logs and Verify Delivery | tailnet_settings; logstream_configuration | Flow logs; stream status/configuration | Client telemetry support; no central log-admin command | Logging.GetNetworkFlowLogs; stream methods | No local policy fragment replaces collection/delivery | Entitled flow/configuration exports |

All “none” entries are bounded to the fetched core-tailnet API/provider/CLI census, not to integrations outside Tailscale. IdP configuration is delegated to the actual identity provider. No vendor-native SQL surface was found or fabricated.

## Fetched control sources

| Control | Sources checked |
|---------|-----------------|
| 1.1 | [Security best practices](https://tailscale.com/docs/reference/best-practices/security), [Entra provisioning and application assignment](https://tailscale.com/docs/integrations/identity/entra/entra-id-scim) |
| 1.2 | [User roles](https://tailscale.com/docs/reference/user-roles), [User approval](https://tailscale.com/docs/features/access-control/user-approval), [Provisioning behavior](https://tailscale.com/docs/features/user-group-provisioning), [OAuth lifecycle](https://tailscale.com/docs/features/oauth-clients) |
| 1.3 | [Device approval](https://tailscale.com/docs/features/access-control/device-management/device-approval), [Tailnet Lock limitations](https://tailscale.com/docs/features/tailnet-lock) |
| 1.4 | [Key expiry](https://tailscale.com/docs/features/access-control/key-expiry), [Tag/key behavior](https://tailscale.com/docs/features/tags) |
| 1.5 | [Tailnet Lock](https://tailscale.com/docs/features/tailnet-lock) |
| 2.1 | [Grants versus ACLs](https://tailscale.com/docs/reference/grants-vs-acls), [Grants syntax](https://tailscale.com/docs/reference/syntax/grants), [ACL defaults](https://tailscale.com/docs/features/access-control/acls) |
| 2.2 | [Policy tests and SSH tests](https://tailscale.com/docs/reference/syntax/policy-file), [Read-only validation scope](https://tailscale.com/docs/reference/trust-credentials) |
| 2.3 | [Tags, identity and ownership](https://tailscale.com/docs/features/tags), [Administrative role permissions](https://tailscale.com/docs/reference/user-roles) |
| 2.4 | [Tailscale SSH](https://tailscale.com/docs/features/tailscale-ssh), [SSH tests](https://tailscale.com/docs/reference/syntax/policy-file) |
| 2.5 | [Posture syntax and attributes](https://tailscale.com/docs/features/device-posture/postures-and-attributes), [Postures in rules](https://tailscale.com/docs/features/device-posture/postures-in-access-rules), [Plan availability](https://tailscale.com/docs/features/device-posture), [Monitoring posture](https://tailscale.com/docs/features/device-posture/monitoring-postures) |
| 3.1 | [Trust credentials and scopes](https://tailscale.com/docs/reference/trust-credentials), [OAuth lifecycle](https://tailscale.com/docs/features/oauth-clients), [Terraform identity federation](https://tailscale.com/docs/integrations/terraform-provider) |
| 3.2 | [Auth keys](https://tailscale.com/docs/features/access-control/auth-keys), [Device preapproval](https://tailscale.com/docs/features/access-control/device-management/device-approval), [Grants](https://tailscale.com/docs/reference/syntax/grants) |
| 3.3 | [Subnet routers](https://tailscale.com/docs/features/subnet-routers), [Exit nodes](https://tailscale.com/docs/features/exit-nodes), [Auto approvers](https://tailscale.com/docs/reference/syntax/policy-file) |
| 4.1 | [Sharing and revocation](https://tailscale.com/docs/features/sharing), [External-tailnet joining](https://tailscale.com/docs/features/sharing/how-to/invite-any-user), [Posture limitations](https://tailscale.com/docs/features/device-posture/postures-and-attributes), [Settings API schema](https://github.com/tailscale/tailscale-client-go-v2/blob/main/tailnet_settings.go) |
| 4.2 | [Funnel exposure and policy changes](https://tailscale.com/docs/features/tailscale-funnel), [Funnel status CLI](https://tailscale.com/docs/reference/tailscale-cli/funnel) |
| 4.3 | [Client updates](https://tailscale.com/docs/features/client/update), [Security best practices](https://tailscale.com/docs/reference/best-practices/security), [Security bulletins](https://tailscale.com/security-bulletins) |
| 5.1 | [Configuration audit structure and limitations](https://tailscale.com/docs/features/logging/audit-logging), [Log scopes](https://tailscale.com/docs/reference/trust-credentials) |
| 5.2 | [Flow logs](https://tailscale.com/docs/features/logging/network-flow-logs), [Log streaming](https://tailscale.com/docs/features/logging/log-streaming), [Streaming status scope](https://tailscale.com/docs/reference/trust-credentials) |

## Complete provider documentation census

The first-party repository tree was fetched at `07f1b994d2d20cf7de3e7fef6e8b02443f84c34a`; shipped schema was cross-checked against 0.29.3 documentation, including users/device data, device-key expiry, complete policy, routes, settings and log streaming. The settings implementation confirms optional/computed fields preserve unspecified state; one resource owns the settings.

**resources:** `acl`, `aws_external_id`, `contacts`, `device_authorization`, `device_key`, `device_subnet_routes`, `device_tags`, `dns_configuration`, `dns_nameservers`, `dns_preferences`, `dns_search_paths`, `dns_split_nameservers`, `federated_identity`, `logstream_configuration`, `oauth_client`, `posture_integration`, `service`, `tailnet_key`, `tailnet_settings`, `webhook`.

**data-sources:** `4via6`, `acl`, `device`, `devices`, `service`, `user`, `users`.

## Semantics checked before authoring

- Grants are recommended for new access policies; existing ACL allows remain additive. The minimal candidate explicitly sets `acls: []`. Restrictive additions do not override wider permissions.
- Device approval and Tailnet Lock are mutually exclusive. Pre-approved auth keys can bypass manual device approval. Lock setup requires independent signer/recovery design and is never executed by a pack.
- User approval and SCIM are mutually exclusive according to the specific user-approval reference. The general provisioning overview recommends user approval when SSO and SCIM use different apps, which conflicts with that limitation. The guide calls out the conflict and relies on scoped IdP assignments and observed provisioning rather than pretending both features can be enabled.
- Tags replace user identity and combine permissions; tagged authentication/re-authentication disables node-key expiry by default. Tailnet expiry changes do not rewrite existing authenticated nodes’ deadlines immediately.
- MFA is configured in the actual IdP. A fresh sign-in test does not prove that existing nodes or tailnet-associated OAuth credentials were removed.
- Source posture is a condition on applicable access rules. Assertions within a posture are AND; multiple postures are alternatives. Explicit source posture replaces the default. Missing applicable attributes fail a match. External sharing and subnet-origin traffic have documented exceptions.
- Funnel is public and its enablement flow can change policy and HTTPS configuration. Only local status is read; no public listener is started.
- Tailscale SSH needs both network and SSH authorization. Named OS accounts are narrower than `autogroup:nonroot` on production tags. Tagged-to-tagged SSH cannot use human check mode.
- A route must be advertised, approved and permitted. Managing enabled routes does not advertise them. The Terraform pack excludes both IPv4/IPv6 default routes and must own the complete intended enabled set.
- `/acl/validate` returns empty HTTP 200 on documented success; nonempty HTTP 200 can carry errors. The collector fails closed on any content. No POST `/acl` exists in the shared transport.
- Raw policy and ETag are retained without typed SDK reserialization. The SDK’s typed posture schema still uses arrays; reserializing a current object-syntax policy through it could discard or reject fields.
- Configuration history is 90 days, nonpaginated, and may be delayed; flow history is 30 days with client/feature limitations. Neither a configured stream nor a status object establishes fresh destination delivery.
- Key listing is credential-relative; known-ID trust review is not credential discovery. `isExternal` is inbound-node evidence, not an outbound share-recipient inventory.

## Local-source SDK compilation fallback

The normal pinned-module download was attempted with checksum verification intact but the module proxy timed out. The SDK and its two production dependencies were then fetched as official Git checkouts into the task’s research directory: SDK 2.12.0 commit `9412c90d30928a9d496f3b30a1dde0d67913b3e9`; oauth2 0.34.0 commit `acc38155b7f6f36aefcb58faff6f36d314dd915c`; HuJSON pinned commit `af5ed07155e52407c9aeaaff2463245383ef19a4`. A separate task-local modfile uses local replacements for testing; the committed module keeps its normal version pin and no replacement path. Tests compile against real upstream code with fake HTTP. This is not a successful standard module-proxy/checksum-database install, and no such result is claimed.

## Security guidance

CodeGuard MCP tools were not enabled; no MCP scan is claimed. Bundled rules applied: no hardcoded credentials (runtime injection and no secret output); modern transport/certificates (normal TLS verification, no insecure flags); input validation and access control (fixed origins/operations and bounded inputs); file/privacy handling (0600 exclusive evidence, no partial output); IaC/DevOps/supply chain (version pins, opt-in resources, no credential creation and explicit policy ownership). Repository lint, transport tests and source/schema review provide the actual local evidence.
