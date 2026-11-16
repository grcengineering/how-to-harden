# Weekly maintenance — November 16, 2026

Base: `403af67350c6a219bfe2e79e939ac9cb2400305c`, current main after PR #153. Scope: inventory the corpus and concurrent work, review recent source discoveries, and reconcile the verified Claude Code self-hosted and Cursor Apps omissions. This is a priority maintenance pass, not a fresh accuracy audit of every control in all 161 guides. **No tenants declared — documentation/offline checks only; VERIFIED-LIVE = 0.**

## Inventory and coordination

The checkout initially supplied was on an older security-bootstrap branch with local deletions, `.gitignore` edits, local agent configuration and scan artifacts. Those were left untouched. Work used an isolated checkout of current main; no existing worktree, branch or memory was rewritten.

| Inventory at base | Observed count / disposition |
|---|---|
| Guides | 161 across 10 categories; 2,281 leveled controls |
| Numbered executable pack sources | 1,467 across 113 vendor directories, counting nested Sigma files |
| Deprecated scanner definitions | 74 numbered `controls/` files; counted separately from executable implementations |
| Pack types | API 499; CLI 165; config 213; SDK 72; Terraform 354; SIEM/Sigma 141; DB 23 |
| Maturity | All 161 hold `ai-drafted`; 16 additionally hold `ai-validated`; no `ni-*` claims |
| Source catalog | Read SOURCES.md and its tier/admission/conflict rules; 52 linked example rows. Existing admitted Pluto research supplies discovery context; no new research organization was admitted |
| Agent Skills | Five `.agents/skills/*/SKILL.md` files read in the original checkout; current main has the five canonical `.claude/skills` playbooks plus shared source/Trust Center discovery workflows. The untracked `.agents` copies were not published or overwritten |

The version-registry caption incorrectly counted seventeen AI-validated guides although its source frontmatter holds sixteen. Regenerating the registry corrected the caption; no maturity status was added or removed.

All open PRs were listed through `gh`, including the older item omitted by the connector search result. [#95](https://github.com/grcengineering/how-to-harden/pull/95) covers supply-chain/security workflows; [#38](https://github.com/grcengineering/how-to-harden/pull/38) covers StepSecurity workflow, dependency and pre-commit files. Neither changes the guide/pack surfaces edited here. No review, merge or message was posted to either PR.

Recent local branches/worktrees and merged PRs were reconciled before writing: [#153 agent guides](https://github.com/grcengineering/how-to-harden/pull/153), [#152 Slack/Snowflake](https://github.com/grcengineering/how-to-harden/pull/152), [#151 Factory](https://github.com/grcengineering/how-to-harden/pull/151), [#150 Wallet](https://github.com/grcengineering/how-to-harden/pull/150), [#148 Pluto](https://github.com/grcengineering/how-to-harden/pull/148), [#147 Claude Tag](https://github.com/grcengineering/how-to-harden/pull/147), [#146 Cursor model access](https://github.com/grcengineering/how-to-harden/pull/146) and [#145 Vercel](https://github.com/grcengineering/how-to-harden/pull/145). Their shipped work was retained rather than repeated. Codex memory-summary paths were searched read-only; no applicable memory file was found or modified.

## Source-first findings and dispositions

Public bodies were fetched on 2026-11-16 with web extraction and HTTPS requests using a browser-compatible user agent. Temporary source captures retained final URLs, body hashes and content identities; no credentials, restricted documents or signed download URLs are committed.

| Candidate and verified source | Conditions / disposition |
|---|---|
| [Claude runner production hardening](https://code.claude.com/docs/en/self-hosted-environments-deploy), [reference](https://code.claude.com/docs/en/self-hosted-environments-reference), [quickstart](https://code.claude.com/docs/en/self-hosted-environments-quickstart) | **OMISSION → Code 3.3.** Public beta, Team/Enterprise; ephemeral workload, capacity one, zero reuse grace, repository guard enforcement and independent egress/metadata controls. A warning-only guard or restarted container is insufficient. Native help corroborated the required flags; no runner registered |
| [On-demand configuration](https://code.claude.com/docs/en/self-hosted-environments-configuration) | **Covered → Code 3.3.** Environment secret remains on the orchestrator; provisioner copies a single-use work order before its temporary source is deleted. Actual provisioning, workload destruction and protected mounts remain deployment-specific and untested |
| [Session identity](https://code.claude.com/docs/en/self-hosted-environments-identity) | **OMISSION → Code 3.4.** Native decoder verifies signature/expiry, not issuer/audience/role. Wrapper adds those checks plus an independently approved actor; no credential mint/exchange. Token identity does not identify the presenting process or authorize every resource |
| [Apps setup/access/security](https://cursor.com/docs/cloud-agent/apps), [release](https://cursor.com/changelog/build-live-apps) | **OMISSION → Cloud Agents 4.4–4.5.** Public versus invited/team audiences, automated key access, admin secrets, publish review and exception authority. Public-to-Team conversion still exposes an app to all team members. Existing Cloud Agents guide already owns saved Apps; a duplicate standalone guide would split this execution plane |
| [Cursor Admin API](https://cursor.com/docs/account/teams/admin-api), [Organization API](https://cursor.com/docs/account/organizations/organization-admin-api), [Cloud API](https://cursor.com/docs/cloud-agent/api/endpoints) | **Unverified administration surface.** Runtime app-token authentication and Origin integration-app installation are distinct from hosted Apps policy. No setting-specific policy/read handle established; no speculative pack |
| [Official Cursor provider v0.9.0 tree](https://github.com/cursor/terraform-provider-cursor/tree/v0.9.0/docs) | **Bounded index check.** Latest tag checked; 9 resource docs and 6 data-source docs, covering Origin/workflows. No hosted Apps policy handle in that index. Existing v0.8.0 examples are not upgraded merely because a new version exists |
| [Anthropic provider v0.3.0 tree](https://github.com/jianyuan/terraform-provider-anthropic/tree/v0.3.0/docs) and [API overview](https://platform.claude.com/docs/en/api/overview) | **Bounded interface check.** Existing community provider's latest tag remains v0.3.0; full resource/data-source list checked. No runner isolation or session-verification handle established there; runtime native interfaces used instead |
| [Pluto blog index](https://pluto.security/blog/), [Grok Bot research](https://pluto.security/blog/securing-grok-bot/), [Copilot Studio research](https://pluto.security/blog/securing-copilot-studio-a-practical-hardening-guide/) | **Previously reconciled / no new control originated.** November 12 RFP and November 11 framework commentary do not supply new product configuration. Existing Grok/Copilot guides and November 12 reconciliation retained; not a claim that every third-party site was freshly swept |
| [GitHub SBOM API](https://docs.github.com/en/rest/dependency-graph/sboms) | **No affected recommendation found in this corpus search.** Synchronous export sunset notice identified; no matching endpoint/SBOM command found in the GitHub guide or packs. No unrelated API example added |
| [Snowflake release index](https://docs.snowflake.com/en/release-notes/all-release-notes) | **Discovery lead / not full product reconciliation.** Recent WIF/approval changes already landed in #152. Postgres token-access-role preview is a candidate for a separate source/control census; this run makes no claim of complete Postgres hardening coverage |

These are existing-product areas, not ownership changes; the Anthropic and SpaceXSI platform chains and control numbers stay stable. Existing account/SSO controls remain in their hubs.

## Trust Center discovery boundary

| Portal → catalog | Search boundary and document dispositions |
|---|---|
| Official Anthropic portal → [public JSON](https://trust.anthropic.com/json) | Examined all 16 returned categories and 72 item metadata entries, including Best Practices/Whitepapers, FedRAMP, HIPAA and Other Documents; no pagination advertised in that response. Existing Unified v1.3.6, Cowork, Code FISMA and C4G documents remain distinct leads with prior body reconciliation in the [November inventory](anthropic-source-coverage-2026-11.md) and [November 14 follow-up](anthropic-unified-baseline-2026-11-14.md). Their PDF bodies were not freshly re-audited here and originate none of the new runner implementation. Restricted HIPAA/architecture resources remain inaccessible, not absent |
| [Cursor security page](https://cursor.com/security) → [official portal](https://trust.cursor.com/) → [public JSON](https://trust.cursor.com/json) | HTML shell identified Vanta; enumerated 32 returned entries across Audit reports, Policies, Useful Links, FAQ, Legal Policies, Penetration Testing Reports, HIPAA Guide and the uncategorized group. The public Cloud Agent Security and Audit Logs links resolve to [configuration](https://cursor.com/docs/cloud-agent/security-network) and [monitoring](https://cursor.com/docs/enterprise/compliance-and-monitoring) bodies. Certification/legal entries excluded as setting evidence. The Shared Responsibility Notion link was discovered but its body could not be read through the web fetcher; no recommendation derived from it. HIPAA Implementation Guide and security-policy/CAIQ/penetration documents are marked restricted; no access requested or reconstructed |

Catalog counts describe returned metadata, not a guarantee of all hidden resources. No portal landing page is used as a hardening-doc button. New doc-link buttons point directly to verified runner/Apps configuration pages.

## Automation census and implementation boundary

| Surface | Claude runner controls | Cursor Apps controls |
|---|---|---|
| Terraform resources / data sources | Full existing provider index checked; no handle established for these controls | Latest official index checked; no hosted Apps policy handle in it |
| REST / GraphQL | API index does not establish runner-policy administration; GraphQL unverified | Admin/Organization/Cloud references checked; hosted Apps policy and GraphQL contracts remain unverified |
| First-party CLI | `claude self-hosted-runner --help`, documented launch flags and `decode-token`; separate verification packs | Existing CLI inventory reviewed; no Apps administration handle verified |
| Official SDK | General API SDK is not runner deployment/session authorization; setting-specific surface unverified | Execution SDK is not proof of Apps admin policy; setting-specific surface unverified |
| Native configuration | Candidate emits documented runner launch flags; no provisioner/network policy fabricated | No dashboard-policy config contract established |
| SIEM / audit | Native health/metrics/logs documented; no tenant-wide detection schema or fabricated query supplied | Team policy audit events documented; event-specific export/detection contract not established |

Claude Code pack coverage changes from **13/13 to 15/15 controls**. Cursor Cloud Agents changes from **2/10 to 2/12 controls** with packs; the new two explicitly retain unverified administration interfaces. The shared Anthropic pack vendor's Check 16 reports the hub separately (**6/11**), which is not the Claude Code product's pack coverage. Anthropic already ships API, CLI, config, SDK and Terraform implementations; these additions do not replace that census with a single-type claim.

Three new packs: candidate launcher emitter (`7.14/config`), help-only capability check (`7.14/cli`), and opt-in native session-identity verifier (`7.15/cli`). File/section/type collisions checked; enforcement preparation and read evidence are labeled separately. Token values stay in injected environment/native processing; output contains no claims or actor IDs. The launcher alone does not contain hostile code. CodeGuard credential, cryptographic, input-validation and logging guidance informed these boundaries; no CodeGuard MCP invocation is claimed because no such tool was exposed.

## Verification and remaining limits

The pre-change whole-corpus pack run reported **5 failure groups**: Bitbucket/Vault section-type collisions; existing Vault and DockerHub Bash syntax; 11 extension/type mismatches; and an Azure DevOps comment-only Terraform file. These predate this branch. It also reported 17 single-type vendors, 22 documented-CLI vendors without CLI packs and 3 CLI vendors missing inventory rows. They are corpus debt, not hidden by a touched-file result.

Offline/native-help, lint, sync, rendered output and touched-file check results are recorded with the PR. Native token/JWKS verification, runner lifecycle/isolation, Apps access and publish rejection were **not exercised live**. No maturity marks or statuses are earned. Production cheat-sheet verification is pending maintainer merge/deployment. Restricted documents, service-specific automation contracts, Snowflake Postgres discovery and the older corpus failures remain explicit follow-up areas; this report does not assert complete cross-vendor accuracy or complete source discovery.
