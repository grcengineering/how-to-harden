---
layout: guide
title: "DeepWiki Hardening Guide"
vendor: "DeepWiki"
slug: "deepwiki"
platform: "Cognition"
platform_slug: "cognition"
product: "DeepWiki"
tier: "2"
category: "AI/ML Platform"
description: "Security configuration for Cognition DeepWiki: public/private repository boundaries, indexing scope, credential-free public MCP, isolated research clients, and reviewed wiki configuration."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-10-30"
---

## Overview

This is a **product guide within the [Cognition platform](/guides/devin/)**. Cognition's [DeepWiki MCP announcement](https://cognition.com/blog/deepwiki-mcp-server) establishes the product's ownership. Private DeepWiki uses Devin's organization and repository controls; the public service does not inherit a customer's Devin SSO, roles, or network policy. Apply the [Devin common controls](/guides/devin/) for private organization access rather than configuring a second identity plane here.

**Two different trust boundaries:** `deepwiki.com` and `mcp.deepwiki.com` serve public GitHub repository documentation. Private repository research belongs in the Devin application or the authenticated Devin MCP service. The latter is not simply a private copy of the public read-only connector: it also exposes platform-management capabilities. [DeepWiki MCP](https://docs.devin.ai/work-with-devin/deepwiki-mcp) and [Devin MCP](https://docs.devin.ai/work-with-devin/devin-mcp) document the distinction.

**Product Editions Covered:** Free public DeepWiki and private repository wikis within a Devin account. Enterprise repository permissions are identified explicitly. This guide does not assume that a free public-service operator has a tenant administration console.

**Validation status:** Documentation checked on 2026-10-29; local configuration checks were exercised with synthetic fixtures. No private tenant, live client integration, or repository authorization boundary was tested. There is no human-review or live-validation claim.

### Intended Audience
- Security and developer-platform teams approving repository documentation services
- Repository owners reviewing what is indexed and how generated content is consumed
- Administrators connecting MCP clients to DeepWiki

### How to Use This Guide
- **L1 (Crawl):** Keep public and private research separate, and use the documented public endpoint without credentials.
- **L2 (Walk):** Audit indexing scope, isolate research clients, and review repository-native generation configuration.
- Apply controls to the surface they name; a client-side check is not server-side enforcement.

### Scope

This guide addresses DeepWiki-specific data routing, indexing, MCP consumption, and wiki configuration. Devin SSO, service-user roles, repository access grants, audit logs, and agent-execution policy belong in the [Devin guide](/guides/devin/). Local execution and client approval rules belong in the [Devin CLI](/guides/devin-cli/) and [Devin Desktop](/guides/devin-desktop/) guides.

No named Devin or DeepWiki CIS Benchmark or CISA SCuBA baseline was identified in the [2026-10-29 research](/research/cognition-sources/). A generic CIS AI MCP Server benchmark exists but is not a product-specific baseline for this hosted service. DISA product coverage remains inconclusive because its index could not be fully verified; no DeepWiki-specific NSA or ACSC configuration guidance was identified. The NIST mappings below are supporting control objectives, not a certification or an independent product benchmark.

---

## Table of Contents

1. [Repository and Data Boundaries](#1-repository-and-data-boundaries)
2. [MCP Client Boundaries](#2-mcp-client-boundaries)
3. [Documentation Configuration](#3-documentation-configuration)
4. [Compliance Quick Reference](#4-compliance-quick-reference)

---

## 1. Repository and Data Boundaries

### 1.1 Keep Private Research in the Authenticated Devin Boundary

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST 800-53 Rev. 5 | AC-3, AC-6 |

#### Description
Use the public DeepWiki service only for information approved for public disclosure. Route private code, incident details, customer information, and private repository questions through your authorized Devin organization. A public repository name does not make a prompt containing internal context public-safe.

#### Rationale
**Why This Matters:**
- Public repository research needs no credential; adding one increases exposure without providing private access.
- A question can reveal sensitive context even when its answer is derived entirely from public code.

**Attack Prevented:** Accidental disclosure through a public research connector and over-broad private repository access.

#### Prerequisites
- A data-classification decision for the intended prompt and repository
- For private work, an authorized Devin account and approved SCM repository grants

#### ClickOps Implementation
1. For public research, open **deepwiki.com** and select an approved public repository. Do not paste private source or secrets into its questions.
2. For private research, open the approved organization in **app.devin.ai** and use its **DeepWiki** or **Ask Devin** interface.
3. Have the Devin administrator enforce the repository grants described in [Devin section 3.1](/guides/devin/#31-limit-repository-and-mcp-access). On Enterprise, the documented review location is **Settings > Repositories**; choose the organization and inspect its configured permissions. Prefer individual repositories over broad SCM groups.
4. Keep a record of which organization is authorized for each private repository; do not treat indexing or wiki steering as an access grant.

The public/private product split is documented by [Cognition](https://cognition.com/blog/deepwiki-mcp-server); Enterprise grant semantics and navigation are documented in [Git Integrations](https://docs.devin.ai/enterprise/integrations/git-integrations).

**Automation:** The human data-classification decision is not a DeepWiki API setting. Repository authorization is administered and audited through the [Devin common controls](/guides/devin/), not a fabricated DeepWiki SSO or ACL API. [Public MCP documentation](https://docs.devin.ai/work-with-devin/deepwiki-mcp), checked 2026-10-29, documents public research tools only.

#### Validation & Testing
- In a non-production test, confirm that an approved user can access the intended private repository and an unapproved user or organization cannot. Use harmless test content; never test by submitting real secrets publicly.
- Treat a missing or empty answer as inconclusive, not proof of authorization denial. Record the explicit access result.
- Recheck the boundary after membership or SCM grant changes. Escalate residual indexed-data access to Cognition rather than assuming revocation proves deletion.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| NIST 800-53 Rev. 5 | AC-3 | Enforce authorized information access |
| NIST 800-53 Rev. 5 | AC-6 | Limit access to required repositories |

### 1.2 Review Indexed Repositories and Additional Branches

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 Rev. 5 | AC-6, CM-8 |

#### Description
Maintain an approved inventory of repositories and branches that DeepWiki indexes. Include repositories added through environment configuration: creating a development environment is not the only workflow that matters to documentation scope.

#### Rationale
**Why This Matters:**
- Old feature or incident branches can contain information outside the intended documentation scope.
- Comparing the current inventory with approvals exposes additions that an initial onboarding review will miss.

**Attack Prevented:** Unreviewed expansion of the source material available to code-search and documentation consumers.

#### ClickOps Implementation
1. In the intended Devin organization, open **Settings > DeepWiki > Repositories**.
2. Compare the listed repositories with the approved inventory. The vendor documents automatic indexing for repositories added to an environment or blueprint.
3. Click each repository to open **Indexed branches**. Review additional branches as well as the default branch.
4. Use **Add > Add repositories** or **Add branch** only for an approved addition. If an entry is no longer approved, stop using it and have the administrator reconcile both repository authorization and indexing. The API has documented repository and branch removal operations; their writes are not executed by these inventory packs.

These indexing paths and automatic-indexing behaviors come from [Index a Repository](https://docs.devin.ai/onboard-devin/index-repo). That page does not document an index-purge or retention guarantee; do not interpret permission removal as proof that stored documentation was deleted.

#### Code Implementation

{% include pack-code.html vendor="deepwiki" section="1.2" %}

The API pack uses the documented [List indexed repositories](https://docs.devin.ai/api-reference/v3/repositories/list-organizations-indexed-repositories) endpoint and follows every cursor. Inject `DEVIN_API_KEY` and `DEVIN_ORG_ID` through your approved credential manager. A scoped service user needs access to the target organization's repository inventory; missing permissions or a malformed response are **unknown**, not a clean audit. Output contains private repository names and branches: keep it in protected evidence storage.

The [official Terraform provider](https://docs.devin.ai/api-reference/terraform-provider) data source reports connected repositories and indexing flags, but not branches. Its native `devin_repository_indexing` resource and the REST write routes can change indexing; these audit packs deliberately omit those writes. Creating an indexing resource starts jobs; destroying it disables indexing and clears configured branches. Review a separate change plan instead of adopting an auto-index-all example. Terraform format checks passed. Provider initialization was attempted with backends disabled on 2026-10-30, but the official registry connection timed out; provider-backed validation, plan, and apply were not performed. The pack was source-checked against provider v0.5.0.

#### Validation & Testing
- Record the organization, repository, branches, owner, and approval date in the organization's protected inventory.
- Resolve every unexpected entry with the repository owner. Recheck after environment changes and at least monthly.
- A connected repository list is not interchangeable with the indexed repository or branch list.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| NIST 800-53 Rev. 5 | AC-6 | Constrain data access to the intended purpose |
| NIST 800-53 Rev. 5 | CM-8 | Maintain an inventory of in-scope components |

## 2. MCP Client Boundaries

### 2.1 Use the Credential-Free Official Public MCP Endpoint

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST 800-53 Rev. 5 | CM-6, SC-8 |

#### Description
Configure public DeepWiki directly at `https://mcp.deepwiki.com/mcp`, with no authentication header, API key, or package-execution wrapper. The configuration pack is a template to merge into an approved client, not a command that overwrites an existing file.

#### Rationale
**Why This Matters:**
- An exact HTTPS destination avoids look-alike endpoints and unnecessary local package execution.
- A credential-free configuration cannot accidentally send a Devin key to a public connector.

**Attack Prevented:** Credential leakage to unnecessary endpoints and substitution of an unapproved local MCP wrapper.

#### ClickOps Implementation
1. Open your approved client's MCP configuration editor. For **Devin Desktop Cascade**, use the panel's **... (Actions) > MCPs > Open MCP config file**. Devin Local uses the separate CLI configuration workflow; follow the [Devin CLI guide](/guides/devin-cli/).
2. Add the public template from the pack below without replacing unrelated approved settings.
3. Confirm the server is remote HTTPS and has no headers or credentials. The standard `url` field is documented; Desktop also accepts `serverUrl`.
4. Reconnect and inspect the tool inventory: the documented public tools are `read_wiki_structure`, `read_wiki_contents`, and `ask_question`. Investigate unexpected tools before use.

Sources: [DeepWiki MCP configuration and tools](https://docs.devin.ai/work-with-devin/deepwiki-mcp) and [Cascade MCP configuration editor](https://docs.devin.ai/desktop/cascade/mcp). The `/sse` endpoint is legacy and being deprecated, not the recommended transport.

#### Code Implementation

{% include pack-code.html vendor="deepwiki" section="2.1" %}

#### Validation & Testing
- Review the effective loaded URL, not only the file you edited. A client can silently ignore an unsupported configuration field.
- Use the read-only audit pack in control 2.2 for a dedicated public-research profile.
- Query a harmless approved public repository. Successful public queries do not establish private-repository authorization.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| NIST 800-53 Rev. 5 | CM-6 | Set and verify approved configuration values |
| NIST 800-53 Rev. 5 | SC-8 | Protect transmission to the approved HTTPS endpoint |

### 2.2 Isolate Public Research from Authenticated Agent Tools

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 Rev. 5 | AC-6, CM-7 |

#### Description
Use a dedicated public-research client configuration that contains only the public DeepWiki connector. Do not silently substitute authenticated Devin MCP. The pack verifies a conservative local profile; it does not claim to sandbox the client or inspect its other configuration layers.

#### Rationale
**Why This Matters:**
- Authenticated Devin MCP can manage sessions, playbooks, knowledge, and schedules, beyond answering repository questions.
- Documentation returned by a public repository is untrusted input; placing it next to privileged tools creates an avoidable escalation path.

**Attack Prevented:** Confusing a documentation-only connector with an authenticated agent-management integration, and inadvertent exposure of privileged tools to untrusted research content.

#### ClickOps Implementation
1. Create or select a dedicated configuration using your client's supported profile mechanism. If it cannot isolate profiles, use a separate client instance or keep the authenticated connector disconnected during public research.
2. Configure only the public DeepWiki entry from control 2.1. Disable other MCP servers, native execution tools, automatic tool approval, and private-context attachments through the client's documented controls. See the [CLI](/guides/devin-cli/) or [Desktop](/guides/devin-desktop/) guide for those separate surfaces.
3. If private research is required, switch to a separately approved workflow. Review the service user's permissions and the actual discovered tool list before enabling **Devin MCP**. The [Devin hub](/guides/devin/) covers service-user authorization.
4. Do not rely on the server name `deepwiki` as a trust decision. Inspect the URL and effective capabilities.

The authenticated service's expanded capability set is documented in [Devin MCP](https://docs.devin.ai/work-with-devin/devin-mcp). Isolation is this guide's compensating control, not a claimed DeepWiki server-side policy.

#### Code Implementation

{% include pack-code.html vendor="deepwiki" section="2.2" %}

Run the script with the path to the **dedicated** MCP JSON file. Exit `0` means that file matches this narrow policy; `1` reports a configuration finding; `2` means it could not be assessed. It reads no credentials into output, performs no network requests, and writes no files. It intentionally rejects extra servers and unrecognized fields instead of certifying a mixed-use profile.

#### Validation & Testing
- Confirm the live client's complete tool inventory matches the isolated workflow; the file check alone cannot see plugins, built-in tools, inherited settings, or environment-injected connections.
- Confirm automatic execution remains disabled in the client and that external documentation cannot grant approvals.
- Re-run the audit after edits. Treat an audit failure as a review requirement, not permission to delete other configurations automatically.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| NIST 800-53 Rev. 5 | AC-6 | Keep research separate from privileged actions |
| NIST 800-53 Rev. 5 | CM-7 | Expose only needed capabilities |

## 3. Documentation Configuration

### 3.1 Review Wiki Generation Configuration as Repository Content

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 Rev. 5 | CM-3, CM-6 |

#### Description
Review changes to `.devin/wiki.json` with the repository's normal change-control process. Validate the documented structure before regeneration and examine the resulting pages. The file directs generation; it is **not** an exclusion list, an authorization policy, or a guarantee that sensitive content cannot be read.

#### Rationale
**Why This Matters:**
- Repository-supplied instructions can change what readers see and which security-relevant areas receive attention.
- Schema validation catches malformed or incomplete plans, but cannot certify the factual accuracy or safety of their prose.

**Attack Prevented:** Unreviewed manipulation of generated documentation and false confidence in a prompt-based data-access boundary.

#### ClickOps Implementation
1. Open `.devin/wiki.json` in the repository editor. If no steering file is needed, leaving it absent is valid; do not add one merely to satisfy this guide.
2. If present, inspect `repo_notes` and every page's `title`, `purpose`, `parent`, and optional notes. Reject secret values and instructions to bypass access controls or execute external actions.
3. Review the intended complete page set. This file replaces the default planning behavior; omitting a security topic may omit its page.
4. After generation, follow the wiki's source links and compare a sample of claims with the underlying code. Keep source permissions and repository review rules as the enforceable boundaries.

The documented file contract and limits are in [DeepWiki repository wikis](https://docs.devin.ai/work-with-devin/deepwiki). The local validator checks required arrays, page-title uniqueness, repository-note limits, and hierarchy consistency. Additional hierarchy checks are explicitly HTH policy, not undocumented vendor guarantees. The vendor describes `page_notes` as an array but does not fully document its item structure; a nonempty array returns **unknown / manual review required**, not a fabricated schema verdict.

#### Code Implementation

{% include pack-code.html vendor="deepwiki" section="3.1" %}

Pass the JSON file path, and optionally `--enterprise` for the documented higher page limit. The default limit is 30 pages; Enterprise allows 80. The script never prints note text and never changes the file. Exit `0` means structural checks passed, not that the contents are safe or access-controlled.

#### Validation & Testing
- Run the validator before a configuration change is accepted; review prose separately.
- Test generated output against source references and report misleading or missing material.
- Do not test exclusions by placing real secrets in a repository. A sentence asking the model to ignore a file is not an ACL.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| NIST 800-53 Rev. 5 | CM-3 | Review configuration changes |
| NIST 800-53 Rev. 5 | CM-6 | Check the supported configuration structure |

## 4. Compliance Quick Reference

These mappings identify supporting objectives in [NIST SP 800-53 Rev. 5](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final); they are not assertions that applying this guide satisfies an entire control.

| NIST control | DeepWiki practice | Guide sections |
|--------------|-------------------|----------------|
| AC-3, AC-6 | Authorized private research and least-privilege scope | 1.1, 1.2, 2.2 |
| CM-3, CM-6 | Reviewed and checked configuration | 2.1, 3.1 |
| CM-7, CM-8 | Restricted capabilities and indexing inventory | 1.2, 2.2 |
| SC-8 | Approved HTTPS connection | 2.1 |

## Appendix A: Edition and Automation Coverage

| Surface | Public DeepWiki | Private wikis within Devin |
|---------|-----------------|----------------------------|
| Repository source | Public GitHub repositories | Repositories authorized in the Devin organization |
| Identity | Public service; no login required for public MCP | Devin account and repository authorization; hub controls apply |
| MCP endpoint | `https://mcp.deepwiki.com/mcp` | `https://mcp.devin.ai/mcp`; broader authenticated capabilities |
| Steering configuration | Review a repository's steering file if used | `.devin/wiki.json`; 30-page limit or 80 for Enterprise |
| Validation here | Offline template and synthetic-fixture tests | No tenant or authorization test performed |

### Automation Surface Census

The DeepWiki-specific surface review checked the [product documentation index](https://docs.devin.ai/llms.txt), the [public MCP reference](https://docs.devin.ai/work-with-devin/deepwiki-mcp), the [private MCP reference](https://docs.devin.ai/work-with-devin/devin-mcp), and the [wiki file reference](https://docs.devin.ai/work-with-devin/deepwiki) on 2026-10-29. Four of five controls have a pack, spanning **API**, **Terraform**, and **config**. Public research is MCP-based; private indexing additionally uses the authenticated Devin API and provider.

| Surface | Verdict for these controls |
|---------|----------------------------|
| Terraform | Available: `devin_repositories` data source (pack); `devin_repository_indexing` resource (documented write surface, deliberately not applied by the audit pack) |
| API / GraphQL | Available: Devin v3 repository indexing list/status and PUT/DELETE routes; read-only inventory pack. Public MCP itself is not a REST or GraphQL tenant-admin API; no GraphQL surface documented |
| CLI | No standalone DeepWiki administrative CLI documented; `claude mcp add` is a client command, not a Cognition CLI |
| SDK | No official DeepWiki administrative SDK documented in the reviewed index |
| Config | Available: MCP client JSON and `.devin/wiki.json`; template plus local read-only verification |
| SIEM | No public-service audit-export schema documented; Devin organization audit handling belongs in the hub |

**Known limits:** No documented public-service SSO, IP allowlist, per-organization DLP switch, or guaranteed private-data erasure is asserted here. Index-disable operations are not an assertion about retention or backup deletion. The local packs do not verify server identity beyond the configured literal URL, probe network behavior, enforce prompt classification, or make the consuming agent safe against all prompt injection.

## Appendix B: References

- [Cognition: The DeepWiki MCP Server](https://cognition.com/blog/deepwiki-mcp-server)
- [DeepWiki repository wikis and configuration](https://docs.devin.ai/work-with-devin/deepwiki)
- [Index a Repository](https://docs.devin.ai/onboard-devin/index-repo)
- [Enterprise Git Integrations](https://docs.devin.ai/enterprise/integrations/git-integrations)
- [Public DeepWiki MCP](https://docs.devin.ai/work-with-devin/deepwiki-mcp)
- [Authenticated Devin MCP](https://docs.devin.ai/work-with-devin/devin-mcp)
- [List indexed repositories](https://docs.devin.ai/api-reference/v3/repositories/list-organizations-indexed-repositories)
- [Official Terraform provider](https://docs.devin.ai/api-reference/terraform-provider)
- [Cascade MCP Configuration](https://docs.devin.ai/desktop/cascade/mcp)
- [NIST SP 800-53 Rev. 5](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final)

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-10-30 | 0.1.0 | ai-drafted | Initial five-control guide; public/private boundary, indexing inventory, five API, Terraform, and configuration packs, and offline tests. No live tenant validation. | Codex |

## Contributing

Report incorrect settings or propose improvements through [GitHub issues](https://github.com/grcengineering/how-to-harden/issues). See the [Contributing Guide](/contributing/) before submitting changes.
