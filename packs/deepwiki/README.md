# DeepWiki Code Pack

Companion to the [DeepWiki hardening guide](https://howtoharden.com/guides/deepwiki/). These packs distinguish public DeepWiki research from private repository indexing in Devin. They do not create sessions, add repositories, trigger indexing jobs, or change tenant settings.

## Files and prerequisites

| Control | File | Requirements and effect |
|---------|------|-------------------------|
| 1.2 | `api/hth-deepwiki-1.02-indexing-inventory.sh` | Bash, curl, Python 3, injected `DEVIN_API_KEY` and `DEVIN_ORG_ID`; paginated GET inventory only |
| 1.2 | `terraform/hth-deepwiki-1.02-repository-inventory.tf` | Terraform, official `cognitionai/devin` provider 0.5.0, injected `DEVIN_TOKEN`, `deepwiki_org_id`; data source only |
| 2.1 | `config/hth-deepwiki-2.01-public-mcp.jsonc` | Template for an approved MCP client; merge only the JSON object manually |
| 2.2 | `config/hth-deepwiki-2.02-audit-research-profile.sh` | Bash, Python 3, dedicated MCP JSON file; checks a narrow isolated public-research profile |
| 3.1 | `config/hth-deepwiki-3.01-validate-wiki-config.sh` | Bash, Python 3, existing `.devin/wiki.json`; schema and HTH hierarchy checks only |

Do not copy the `.jsonc` comments into a client that accepts only JSON. Do not replace an existing client configuration with the template without reviewing its current settings. The profile audit deliberately rejects extra servers and settings; use it on a dedicated configuration, not a mixed-use profile.

## Local read-only checks

From the repository root:

```bash
bash packs/deepwiki/config/hth-deepwiki-2.02-audit-research-profile.sh /path/to/dedicated-mcp.json
bash packs/deepwiki/config/hth-deepwiki-3.01-validate-wiki-config.sh /path/to/repo/.devin/wiki.json
# Only when the target organization is Enterprise:
bash packs/deepwiki/config/hth-deepwiki-3.01-validate-wiki-config.sh /path/to/repo/.devin/wiki.json --enterprise
```

Exit `0` means the stated local structural policy passed, not that a tenant is compliant. Exit `1` is a finding. Exit `2` means the input could not be assessed. The scripts do not print configuration values, notes, or credentials. They do not edit their input files.

The wiki checker does not invent the undocumented item shape for optional `page_notes`. A nonempty array returns `2` for manual review. Empty or omitted `page_notes` is supported; the script checks the documented repository-note shape, page requirements, limits, and clearly identified HTH hierarchy rules.

## Authorized private indexing inventory

Use a service user with only the target organization's required repository-read permissions. Obtain its current `cog_` credential through the [documented Devin service-user workflow](https://docs.devin.ai/api-reference/authentication), then inject `DEVIN_API_KEY` and `DEVIN_ORG_ID` with the organization's credential manager. Do not paste a key into shell history, a committed `.env`, or a Terraform variable file.

```bash
# Run only after the two environment variables have been securely injected.
bash packs/deepwiki/api/hth-deepwiki-1.02-indexing-inventory.sh
```

The endpoint is fixed to `https://api.devin.ai`; curl configuration files and redirects are disabled. The credential is supplied to curl through stdin, not its process arguments. Cursor pagination is completed before any inventory is emitted. An HTTP/authentication error, malformed response, missing pagination field, repeated cursor, duplicate repository, or page-limit interruption exits `2` without a partial inventory or a false clean result. A 20 MiB per-response limit bounds parsing. The explicit-pagination requirement is an HTH fail-closed policy, stricter than the OpenAPI default for an omitted flag. Exit `0` means a complete inventory was obtained, **not** that every repository or branch is approved.

Output includes repository names and branches. Keep it in protected audit storage. Temporary files use owner-only permissions and are removed on exit. Compare the result with your approved repository/branch inventory and investigate differences manually.

## Terraform scope

The data source uses the provider's `DEVIN_TOKEN` environment variable (different from the API script's `DEVIN_API_KEY`). Set `deepwiki_org_id` through your approved Terraform input workflow. Copy this pack into a dedicated empty Terraform working directory so an audit does not accidentally include unrelated managed resources. Pin and review the dependency lock file before using the provider.

The data source reports connected repositories and their `indexing_enabled` flags. It does **not** expose the indexed branch list; use the API pack for that. Sensitive output presentation does not encrypt Terraform state or plan files. Protect both.

The provider's real `devin_repository_indexing` resource is deliberately not included: creating or expanding it starts indexing jobs, and destroying it disables indexing and clears branch configuration. Those changes require a separately approved change plan. Terraform format checks passed. Provider initialization was attempted with backends disabled on 2026-10-30, but the official registry connection timed out; provider-backed validation, plan, and apply were not performed. Schema and source review is not `terraform validate` or a tenant test.

## Offline regression tests

```bash
python3 scripts/test-deepwiki-packs.py
for file in packs/deepwiki/config/*.sh packs/deepwiki/api/*.sh; do bash -n "$file"; done
```

The test suite uses synthetic temporary files and a stub curl executable; it never contacts Devin or DeepWiki. It covers valid and invalid MCP settings, credential redaction, JSON ambiguity, wiki limits and hierarchy, API pagination, denied requests, malformed responses, and rejection of unsafe input before a request.

**Validation recorded 2026-10-29:** 20 offline tests passed; all three shell scripts passed Bash syntax checks. No live tenant, client integration, provider execution, or private repository access test was performed. The guide remains `ai-drafted`.
