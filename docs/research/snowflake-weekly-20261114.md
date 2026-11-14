# Snowflake: WIF boundaries and independent approval

Checked 2026-11-14 against main `5e9504e2901313138d86fdc610eb4d754bff7a92`.
This is a bounded update to WIF (§1.5) and a new MPA control (§1.6), **not a
complete Snowflake currency review**. Existing v0.4.1 had WIF setup but no
provider/account/issuer policy boundary and no MPA coverage. Ownership remains
recorded as Snowflake; this pass makes no corporate reclassification.

## Source-first candidates

Bodies below were fetched publicly through web retrieval in this run. The first
three SQL references were additionally retrieved as vendor-published Markdown.
No tenant was accessed and no policy was applied.

| Candidate / source | Plane and conditions | Disposition |
|---|---|---|
| [WIF hardening](https://docs.snowflake.com/en/user-guide/workload-identity-federation#hardening-your-security-posture) | Authentication policy can narrow trust beyond individual workload binding | Covered in 1.5; preserve binding and verify effective assignment |
| [CREATE AUTHENTICATION POLICY](https://docs.snowflake.com/en/sql-reference/sql/create-authentication-policy) | `WORKLOAD_IDENTITY_POLICY` supports provider and account/issuer lists; unset lists are permissive within that dimension | Available; DB 1.05 is a new unattached AWS-only example; CLI 1.05 describes a specified policy |
| [CREATE MULTI PARTY APPROVAL POLICY](https://docs.snowflake.com/en/sql-reference/sql/create-multi-party-approval-policy) | Business Critical+; required self-protection operation; self approval defaults true | Available; 1.6 explicitly chooses independent review; DB example does not attach/replace |
| [MPA](https://docs.snowflake.com/en/user-guide/multi-party-approval) | Console configuration/activation; operational impact on protected automation and approver lifecycle | Covered in 1.6 rollout and recovery checks; no automatic activation/voting/replay |
| [DESCRIBE MPA policy](https://docs.snowflake.com/en/sql-reference/sql/desc-multi-party-approval-policy) | Read existing definition | Available; CLI 1.06, not proof of activation |
| [Agent identity](https://docs.snowflake.com/en/user-guide/agent-identity) and [Restricted Session Scope](https://docs.snowflake.com/en/user-guide/restricted-session-scope) | Separate agent classification, masking and session ceilings | Discovered and body-read; remains a substantive guide gap outside this bounded implementation, queued for dedicated review |

## Surface census

Write and read are separate files: native SQL examples create definitions; CLI
scripts read them. This does not claim all documented transports have packs.

| Surface | Evidence/status | Implementation or remaining gap |
|---|---|---|
| Terraform resources AND data sources | Registry index/search identifies `snowflake_authentication_policy` and `snowflake_authentication_policies`; individual latest pages returned a JavaScript shell. Current indexed schema includes WIF fields. Repo pins the old `Snowflake-Labs/snowflake ~> 0.90`. | **Unverified exact compatibility**; no new fields injected into that module. A separately tested provider migration and read/write packs remain work. MPA provider coverage unverified, not absent. |
| REST and GraphQL | [SQL API](https://docs.snowflake.com/en/developer-guide/sql-api/index) submits statements and reads results. Dedicated policy API/schema and GraphQL census incomplete. | Native SQL is supplied; no bespoke credential/polling wrapper added. REST/GraphQL coverage remains a gap, not a no-API claim. |
| First-party CLI | Inventory row 104 identifies `snow`; [snow sql reference](https://docs.snowflake.com/en/developer-guide/snowflake-cli/command-reference/sql-commands/sql) verifies query, connection, templating, format and exit flags. | Available; two read-only inspectors, with strict identifier validation and propagated failures. SQL creation is a separate reviewed action, not bundled into inspectors. |
| SDK | [Python connector](https://docs.snowflake.com/en/developer-guide/python-connector/python-connector-example) provides SQL transport. Dedicated policy objects not exhaustively reviewed. | No duplicated SDK transport or compatibility claim; remains unimplemented. |
| Native config / DB | Fetched SQL command references contain native WIF properties and MPA YAML inside SQL. | Available; 1.05 and 1.06 DB templates, no profile-independent deployment loop. |
| SIEM | [MPA policy usage view](https://docs.snowflake.com/en/sql-reference/account-usage/multi_party_approval_policies) and MPA workflow expose audit sources. | No SIEM schema/event names invented. Export latency, grants and request fields require a separate validated detection pack. |

There are multiple documented transports, so one native SQL example is not
reported as exhaustive automation. CLI read-back is included now; provider/API/
SDK/detection coverage remains explicit. Existing SnowSQL and Terraform packs,
including pre-existing broad mutation examples, were not validated in this pass.

## Trust Center discovery boundary

Searches for Snowflake customer configuration/security guides surfaced the
[public resources catalog](https://trust.snowflake.com/resources), the public
technical-tools document and the product's unrelated in-account Trust Center.
The resources catalog returned no readable body in web retrieval, so category
counts, pagination, adjacent government editions and private documents remain
**unverified**. No access request, login, NDA acceptance or guessed download route
was attempted. The technical-tools PDF was discovered but not read; no requirement
is attributed to it. The in-account scanner docs are not a substitute for this
vendor assurance catalog. This limitation prevents a comprehensive-baseline claim.

## Verification

- Offline CLI tests: valid read query, invalid identifier rejection before tool
  execution, connection treated as one argument, disabled client templating, and
  nonzero Snowflake CLI exit propagation.
- SQL template checks: no attachment, replacement, activation or user mutation;
  MPA example explicitly disables self approval and includes self protection.
- These tests do not parse SQL against Snowflake or prove edition entitlement,
  console paths, account assignment, enforcement or recovery.
- Repo-wide pack baseline has existing failures outside these additions; final
  generated-data and touched-file checks are coordinated by the integrating task.
- No live-validation maturity badge is added.
