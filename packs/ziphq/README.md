# ZipHQ evidence Code Packs

Packs 1.01, 1.02 and 1.04 are **Microsoft Entra ID verification only**, not Zip-native hardening or enforcement. Each standalone Bash pack invokes curl for documented Microsoft Graph v1.0 GET requests and Python 3 standard-library parsing. They make no configuration changes and never request or obtain credentials. Five additional native Zip API collectors are documented below. All eight packs collect review evidence only.

## Entra prerequisites and execution

Use Bash, Python 3, and curl 8.4 or newer. Supply an existing, appropriately authorized `GRAPH_ACCESS_TOKEN` and `ZIP_ENTRA_SERVICE_PRINCIPAL_ID` through a secure environment injection mechanism. The latter is the **Object ID of the Zip enterprise application**, not the application/client ID. Verify the selected enterprise app in Entra before running: the pack cannot independently establish that a supplied service principal belongs to Zip. Do not paste credentials into commands, enable tracing, or run in an untrusted environment.

Run the selected file with Bash from `packs/ziphq/api/`. Each complete excerpt is standalone; no shared helper files are required.

| Pack | Read-only permission | Evidence |
|------|----------------------|----------|
| 1.01: review-saml-service-principal | Delegated or application `Application.Read.All` | Enabled state, whether SAML is selected, and assignment-required flag; no identifiers |
| 1.02: review-app-assignments | Delegated or application `Application.Read.All` | Deduplicated assignment counts by User, Group and ServicePrincipal |
| 1.04: review-provisioning-jobs | Delegated `Synchronization.Read.All`, or an already-authorized application with `Synchronization.Read.All` | Deduplicated job counts by status bucket and presence of successive failures; no identifiers or error details |

Delegated tokens also require an appropriate Entra role as documented by the endpoint. The synchronization endpoint lists `Application.ReadWrite.OwnedBy` as its least application permission, but this collector deliberately uses only the supported read-only `Synchronization.Read.All` alternative. Do not grant write permissions just to run these collectors.

## Entra result interpretation

Every successful run prints JSON with `result: review-required`. Exit 0 means evidence collection succeeded, **not that a control passed**. Nonzero exit means evidence is unavailable or incomplete; no partial counts are emitted. Empty collections are valid evidence of no returned assignments/jobs, not proof of secure configuration. Unknown job status strings are represented as `Other`, never printed verbatim.

Pack 1.1 does not prove Zip enforces SSO or MFA. Pack 1.2 supports a require-assignment policy: pair its counts with the assignment-required flag from 1.1 and a human access review. Counts measure assignments, not effective users; group membership is not expanded, and replication delays can affect recently changed assignments. Pack 1.4 does not prove correct provisioning scope or successful deprovisioning in Zip. Test a controlled offboarding scenario and review the provisioning logs in the authorized tenant separately.

## Entra safety and boundaries

- Global Microsoft Graph only: `https://graph.microsoft.com`. Sovereign cloud endpoints are intentionally unsupported.
- Every nextLink must retain the exact HTTPS authority and original endpoint path. Host suffixes, userinfo, ports, path changes, fragments, control characters and backslashes are rejected before authentication is forwarded. Redirects are not followed.
- At most 100 pages, 100,000 unique records, 10 MiB per response, 10-second connect timeout and 60-second request timeout. Repeated cursors fail; identical duplicate record IDs count once; conflicting summary data for one ID fails.
- Tokens go to curl's standard-input configuration, not arguments, files or printed output. Shell tracing is disabled before credentials are read. The curl child does not inherit the token environment variable. Default curl config is disabled with `-q`.
- HTTP errors (including throttling) and malformed schemas fail closed without response-body output. No automated retries or mutations occur.

## Entra sources and validation

Fetched November 8, 2026; all three Graph handles are documented v1.0 endpoints:

- [Get servicePrincipal](https://learn.microsoft.com/en-us/graph/api/serviceprincipal-get?view=graph-rest-1.0)
- [List appRoleAssignedTo](https://learn.microsoft.com/en-us/graph/api/serviceprincipal-list-approleassignedto?view=graph-rest-1.0)
- [List synchronization jobs](https://learn.microsoft.com/en-us/graph/api/synchronization-synchronization-list-jobs?view=graph-rest-1.0), including the documented `status` object, `code`, and `countSuccessiveCompleteFailures` response shape
- [Zip provisioning with Microsoft Entra ID](https://learn.microsoft.com/en-us/entra/identity/saas-apps/zip-provisioning-tutorial)
- [ZipHQ guide](https://howtoharden.com/guides/ziphq/)

Validation is Tier 0 static checking and Tier 1 offline mocked execution only. **No real Zip or Entra tenant was used**, and no live-validation claim is made. Run `python3 scripts/test-ziphq-packs.py` for HTTP failures, invalid input/schema, empty collections, counts, deduplication, pagination bounds, malicious/repeated cursors and credential-output/argv checks. The isolated GitHub Actions workflow runs this suite without secrets.


## Native Zip API collectors

Authenticated Zip API documentation was reviewed on November 8, 2026. These GET-only collectors use the fixed `https://api.ziphq.com` origin and preserve the original endpoint and filters on every page. They do not call Microsoft Graph, enforce settings, modify users, or create keys.

**Authentication version conflict:** the prose versioning guide identifies `2024-06-06`, while the current OpenAPI specifies bearer JWT authentication beginning with `2026-07-01`. These packs explicitly pin **legacy API-key version `2024-06-06`**, not “latest.” They are appropriate only where that legacy mode remains supported. Do not substitute a newer version or a JWT. A `ZIP_API_VERSION` environment value other than `2024-06-06` is rejected. Support for newer authentication requires separate verified implementation.

Supply an existing restricted **Read only** key in `ZIP_API_KEY` using secure environment injection. Zip's key UI uses per-record permissions; no exact scope strings such as `users.read` are claimed. Grant only the record types required by the selected collector. These packs neither create credentials nor expand permissions. Dependencies remain Bash, Python 3 standard library and curl 8.4 or newer.

| Pack | Endpoint | Inputs beyond the key | Result and limits |
|------|----------|-----------------------|-------------------|
| 1.05 Review Native SSO Exceptions | GET `/users` | Optional `ZIP_APPROVED_SSO_EXCEPTION_IDS`: comma-separated approved user UUIDs | Counts observed active users with SSO enforcement false, true or unknown. Approved exceptions never become an automatic pass. |
| 1.06 Review Permission Group Memberships | GET `/users` | Optional `ZIP_APPROVED_GROUP_IDS`: comma-separated approved permission-group UUIDs | Counts observed memberships and memberships outside an explicit baseline. No name heuristics; approval roles are not RBAC. |
| 2.04 Review Approval Delegations | GET `/delegations?is_active=true` | None | Counts returned statuses and time/principal completeness. The filter includes ACTIVE and UPCOMING, and excludes expired/invalid inventory. |
| 2.05 Review Queue Approval Visibility | GET `/queues/{queueId}` | Mandatory `ZIP_QUEUE_ID`: one known, approved queue UUID | Deduplicated owner/member counts and nullable visibility/notification flags. No queue enumeration. |
| 4.02 Collect Native Audit Evidence | GET `/event_logs` | Mandatory `ZIP_CREATED_AFTER` and `ZIP_CREATED_BEFORE`: integer epoch seconds | Premier required. Increasing window of at most 31 days, a collector safety limit rather than a documented vendor limit. Aggregate counts only. |

Run the selected standalone shell file with Bash. Baselines are UUIDs, not display names, and are never printed. Without a baseline, results are an inventory requiring human review. No baseline is inferred from group names. Permission-group grants are additive; membership lists do not disclose complete group policies or effective access. The API's approval roles represent hierarchy rather than RBAC.

### Native result semantics

- Every successful run reports `review-required`. `collectionComplete` means only that the returned pagination sequence terminated normally, not that all account objects or historical activity were available.
- The default `/users` deactivated-filter behavior is undocumented in the reviewed schema. These packs describe **observed users**, never an exhaustive active-and-inactive roster or global SSO enforcement. They do not prove MFA enforcement.
- Missing optional booleans, groups, timestamps and actor fields remain unknown. Explicit malformed values fail rather than becoming false/empty. Missing or malformed record IDs fail the run because safe deduplication cannot be established. Unknown delegation or actor values are counted as unknown.
- Audit output contains only counts, the requested window and collection metadata. Known documented event names have individual buckets; other returned types count in `OTHER_OR_UNKNOWN`. The open event-type string is not treated as a closed enum. No IDs, arbitrary event text, API keys, actor names, user data, IPs, descriptions or raw data are printed. An MCP event with a visible human creator can have actor type USER; MCP counts alone do not represent all MCP-originated activity.
- Empty results are review evidence, not proof that logging is disabled or a control passes. Audit `total == 10000` can mean at least 10,000: neither `total` nor `size` is used as a pagination stop. When present, `size` must equal the current response list length before deduplication. Optional `total` is validated only as a nonnegative integer, not compared with the observed or deduplicated record count. Only an absent or null `next_page_token` ends collection; a present empty string is undocumented and fails closed.
- Audit filter boundary inclusivity and whether filtering uses storage time versus the returned event timestamp are not established by the reviewed documentation. The outside-window timestamp counter is diagnostic, not a completeness guarantee. Do not assume adjacent windows partition events exactly; plan overlap and ID-based deduplication when combining windows.
- The active delegation view cannot establish the same-or-higher approval-hierarchy restriction or prove full delegation-policy compliance. No delegation is created, updated or removed.

### Native safety contract

All native packs disable curl's default config, redirects and proxies, use verified HTTPS/TLS, and pass credentials through curl standard-input config rather than command arguments or files. The curl child does not inherit `ZIP_API_KEY` or `GRAPH_ACCESS_TOKEN`. The destination cannot be overridden. Cursor strings are opaque, URL-encoded `page_token` values; even a URL-looking token cannot become a request destination or override original filters.

The queue collector makes one GET with no query parameters, verifies the returned ID, and reports only aggregate membership counts and true/false/unknown visibility and notification states. Missing arrays are unknown; null arrays are invalid. It cannot establish tenant-wide coverage or separation of duties from assignment logic.

Collection requests use `page_size=100`, `sort_by=created_at`, and `sort_order=asc`. At most 100 pages, 10,000 unique records, 10 MiB per response, a 10-second connect timeout and a 60-second request timeout are allowed. Pack 1.06 additionally caps retained projections at 100,000 distinct user-group pairs across users (a collector memory limit, not a vendor maximum); exceeding it fails without truncation or partial evidence. Identical safe projections for a duplicate ID count once; conflicting projections fail. Repeated cursors or exhausted limits fail without partial stdout evidence. HTTP failures, including 401/403/405/429 and server errors, fail closed without exposing bodies. There are no automatic retries; after checking permissions, licensing or throttling, the operator may retry. The documented 150,000-request daily per-key quota does not imply a known reset time.

### Native sources and tests

- [Getting started](https://developers.ziphq.com/zipapidocs/docs/getting-started)
- [Authentication, key creation and webhooks](https://developers.ziphq.com/zipapidocs/docs/rest-api-info-authentication-api-key-creation-and-webhooks)
- [Versioning](https://developers.ziphq.com/zipapidocs/docs/versioning)
- [OpenAPI specification](https://developers.ziphq.com/zipapidocs/openapi/openapi.yaml)
- [Search users](https://developers.ziphq.com/zipapidocs/reference/searchusers)
- [Assign permission groups to users](https://developers.ziphq.com/zipapidocs/docs/use-case-assign-permission-groups-to-users)
- [Search delegations](https://developers.ziphq.com/zipapidocs/reference/searchdelegations)
- [Get queue by ID](https://developers.ziphq.com/zipapidocs/reference/getqueuebyid)
- [Query audit logs](https://developers.ziphq.com/zipapidocs/reference/queryauditlogs)

Run `python3 scripts/test-ziphq-native-packs.py` for native offline fixtures and `python3 scripts/test-ziphq-packs.py` for Entra fixtures. The isolated workflow runs both. Native tests exercise invalid inputs, version mismatch, HTTP/transport/JSON/schema failures, missing fields, baseline counts, unknown status/type values, redaction, opaque hostile cursors, deduplication/conflicts and page limits. Only Tier 0/static and Tier 1/mocked validation has been performed. **No live Zip tenant or native API was called.**

### Help documentation interpretation

These Help Center findings inform human review; they do not change the collectors' `review-required` semantics or authorize remediation:

- **Queue visibility:** “All queue members can view approvals” is on by default and also lets a member complete another member's assigned approval. Review this as an approval boundary, not merely a display preference. [Queues](https://docs.ziphq.com/hc/en-us/articles/19202122220315-Queues).
- **Delegations:** the same-or-higher hierarchical-level restriction is off by default; users without a role can still delegate to any active user. The collector cannot verify that setting or effective hierarchy. [Out of Office Delegations](https://docs.ziphq.com/hc/en-us/articles/21484342605211-Out-of-Office-Delegations-Page).
- **Permission groups:** grants are additive. Advanced permissions allow replacing Default after another group is assigned, while the older API guide describes Default as non-removable in the UI. Verify the tenant's framework rather than treating either behavior as universal. [Advanced permissions](https://docs.ziphq.com/hc/en-us/articles/18921746955035-Permission-Settings-and-Groups) and [API assignment guide](https://developers.ziphq.com/zipapidocs/docs/use-case-assign-permission-groups-to-users).
- **Native SSO:** enforcement can be edited in the Security and Users UI, but the reviewed user PATCH contract does not expose `sso_enforced`. The API collector remains evidence-only. [Security Page](https://docs.ziphq.com/hc/en-us/articles/25604138623899-Security-Page) and [update-user contract](https://developers.ziphq.com/zipapidocs/reference/updateuserbyid).
- **API-key IP restrictions:** Any IP address is the default. Deleting a key's last allowed IP group reverts it to any-IP access rather than denying access. These collectors cannot inspect that setting. [IP Allowlists](https://docs.ziphq.com/hc/en-us/articles/46225974720795-IP-Allowlists) and [API Page](https://docs.ziphq.com/hc/en-us/articles/20210802709275-API-Page).
