---
layout: default
title: "Factory Family Refresh Validation"
permalink: /research/factory-refresh-validation/
---

# Factory Family Refresh Validation

Run date: **2026-11-05**. No tenants declared — **Tier 0+1 only**. No live setting, credential, IdP, agent, daemon, model session, integration, cloud account or self-hosted deployment was exercised. All four guides remain **ai-drafted**; local tests and rendered pages do not earn a live-validation badge.

## Delivered Scope

| Guide | Controls | Pack-backed controls | Source packs | Types |
|-------|---------:|---------------------:|-------------:|-------|
| Factory Common Controls v0.2.0 | 24 | 18 | 26 | Config 15, REST 4, CLI 6, official SDK 1 |
| HumanLayer v0.1.0 | 8 | 4 | 4 | Config 2, CLI 2 |
| Mentlio v0.1.0 | 5 | 0 | 0 | Explicit UI/manual and unverified automation contracts |
| Fenic v0.1.0 | 3 | 2 | 3 | Config 1, official SDK 2 |
| **Total** | **40** | **24** | **33** | Helpers excluded |

Factory began with 19 controls and 23 packs (16 pack-backed). All 19 numbered titles/anchors are preserved. Five admitted omissions address native credential/browser persistence, client updates, delegation identity, automation triggers and runtime secrets. HumanLayer, Mentlio and Fenic have separate native control planes; common Droid policy is not presented as configuring them. Hosted Typedef administration remains a named source gap, without a stub guide.

## Local Checks

| Check | Result and limit |
|-------|------------------|
| `bun test scripts/test-factory-refresh.test.ts scripts/test-fenic-packs.test.ts` with isolated `FENIC_PYTHON` | **65 passed, 0 failed, 394 assertions.** Temporary CLI/transport fakes cover new Factory/HumanLayer process boundaries. Fenic tests import the actual official v0.13.0 classes, not a replacement SDK. |
| Existing `python3 scripts/test-factory-packs.py` | **34 passed**; retained Factory pack contract tests. No live API/CLI substituted for these fixtures. |
| ShellCheck on Factory/HumanLayer shell helpers and packs | Passed. One narrow SC2016 suppression documents the intended literal deferred credential reference in the gateway generator. |
| `bash scripts/validate-guides.sh` | Passed across **141 guides**, zero warnings; product↔hub links and maturity sets valid. |
| Pack sync | `scripts/sync-packs-to-data.sh` regenerated Factory/HumanLayer/Fenic YAML. Unrelated files were restored only after proving their diff was the generated timestamp. No hand-edited generated data. |
| Jekyll | Passed with strict frontmatter, disk cache disabled; final build 5.453 seconds. Used repository-first existing cached Ruby gems with a local compatible validation Gemfile. No dependency file in the unrelated cached checkout was changed. Repository CI remains the authority for its own dependency environment. |
| Source anatomy/render comparison | All 40 controls have Description, Rationale, Why, Attack Prevented, ClickOps, validation and an actual pack or automation verdict. No raw code fences. All **33 rendered pack excerpts match generated source excerpts exactly** after HTML entity decoding. All 19 original Factory numbered titles retained. |
| Actual browser render | Owned isolated `factory-refresh` browser group, loopback preview. Factory **24 rows / 26 excerpts**; HumanLayer **8 / 4**; Mentlio **5 / 0**; Fenic **3 / 3**. Factory/HumanLayer/Mentlio structured tables have populated Description/Rationale cells. Fenic small DOM queries confirmed **9 cells, 0 empty** after a table-response timeout. Factory, HumanLayer and Fenic details were expanded; nonempty code blocks appeared. Full-page response timeouts were checked with smaller queries and are not reported as successful text captures. |
| OCEAN | Canonical local `/Users/p4gs/Code/grcengineering/OCEAN/target/release/ocean build --validate --source /Users/p4gs/Code/grcengineering/OCEAN/checks` passed **197 templates**. No Factory/HumanLayer/Mentlio/Fenic canonical module/check was mapped, so this is toolchain/template validation, not a live product/control result. PATH's older OCEAN lacked the build subcommand. |
| Git whitespace | Authored-source staged whitespace check excludes generated pack YAML. The sync serializer emits indented blank lines and an EOF blank in new Fenic/HumanLayer YAML; these are retained for exact sync freshness, with a separate normalized whitespace check. No generated YAML is hand-edited. Signed commit and branch-aware pack gate are publication checks; final PR CI is reported separately. |

The full baseline pack sweep had **5 failure groups and 6 warnings outside this family** (legacy collisions, syntax/type/substance debt). The previous Factory-only refresh sweep retained that baseline with no Factory/HumanLayer finding. The final sweep stalled at zero CPU reading an unchanged Fivetran Terraform file; only that validator's process tree was stopped. A final exact committed-HEAD Git archive under `/tmp`, using the existing worktree Git metadata read-only for `--touched`, avoids the hydration stall without rewriting unrelated files. Its actual verdict must be recorded before publication; unchanged global debt is not called a family failure or silently fixed here.

## Meaningful Pack Boundaries

The new Factory API reader uses the documented organization Computer-secret names GET, fixed HTTPS origin, GET-only transport, no curl config/redirects, stdin bearer and private complete output. It projects names only, rejects malformed/duplicate data and exposes neither raw error bodies nor secret fields. Names are not values, personal overrides, process access or proof of least privilege. Client checks run `--version`/`update --check`, never install an update.

HumanLayer logout defaults to dry run and executes the actual production command only with `HTH_APPLY=1`; failures do not publish raw CLI diagnostics. The Linear companion read uses an explicit team and the actual first-party package contract, publishes a new private complete file and refuses existing paths/symlinks. Workspace generation sets a reviewed source and setup blocking without pretending empty `copyGlobs` removes defaults. Gateway generation retains a literal secret reference and rejects unsafe URL/shell inputs.

Fenic's official SDK language is Python, a necessary type-fit exception; test orchestration is Bun/TypeScript. The isolated v0.13.0 install needed explicit `tqdm==4.67.1` and `httpx==0.28.1` for missing upstream runtime imports. Real-class tests reproduced ignored `enabled=False`, correct `None` cache-off, the `ignore`/`exclude` discrepancy and inconsistent seconds/minutes TTL bounds. New SDK packs avoid Session creation and model-bearing SemanticConfig validation, which can fetch OpenRouter's catalog. During investigation that distinct validation path attempted a DNS-denied public catalog lookup; no provider credential, inference or Session was used. The test process denies all DNS/connect attempts and binds except urllib3's exact import-only IPv6 capability probe `('::1', 0)`. That exception does not permit a server listener or general network access.

## Source and Runtime Limits

The [source-first ledger](/research/factory-source-coverage/) records initial candidates before control selection, actual configuration evidence, acquisitions/product boundaries, admitted older omissions, six-surface read/write decisions and exclusions. Local research artifacts capture 23 retrieved public reference pages plus versioned SDK source. Vendor configuration claims are explicitly single-sourced unless a second source is named; this is not an exhaustive discovery or independent runtime guarantee.

Unresolved contracts include general Factory audit API/schema and exact native login-cache protection/status; hosted Typedef administration; HumanLayer hosted lifecycle/export/migration, default sharing, organization identity and automation entitlement; Mentlio complete role/scopes/native storage/MDM/API contracts; and Fenic physical response-store purge/encryption, cloud identity and remote MCP authentication/ACLs. Fresh full provider-resource/data-source/GraphQL, product-specific benchmark and independent incident coverage remains incomplete. No unavailable source is labeled verified absence, and no generic host/application control fills the gap.

## Publication

Publication is a signed commit, pushed family branch and **draft PR only**. No approval or merge. CI must be read from the actual draft PR after push; local success is not a green-CI claim. Any failures attributable to this branch must be corrected before handoff.
