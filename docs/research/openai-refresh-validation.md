---
layout: default
title: "OpenAI family refresh validation — 2026-11-05"
permalink: /research/openai-refresh-validation/
---

# OpenAI family refresh validation — 2026-11-05

This record covers the OpenAI refresh from base `99eaa3d1a38ce28ed421ac4020e37e898ea98c9e`, following the updated source-discovery, guide, pack and verification skills. **No live tenants were declared; VERIFIED-LIVE = 0.** Offline tests and documentation review earn no maturity promotion. Ona retains dated historical marks only for unchanged console surfaces; changed API transports and changed console instructions lose their prior marks.

## Source coverage and scope

Research inventories preceded control selection. The [family ledger](/research/openai-source-coverage/) records current product/ownership/lifecycle dispositions, common workspace controls, Dots, Work/Codex, personal-account exceptions, current primary references, admitted security-research leads and bounded baseline searches. Separate ledgers reconcile [API Platform](/research/openai-api-source-coverage/), [Ads](/research/openai-ads-source-coverage/), [Ona](/research/ona-source-coverage/) and [Statsig](/research/statsig-source-coverage/). Control counts measure the authored corpus, not discovery completeness.

| Guide | Leveled controls | Controls with pack includes | Numbered pack files | Types |
|-------|------------------|----------------------------|---------------------|-------|
| ChatGPT Enterprise / Common | 34 | 2 | 2 | API |
| ChatGPT Dots | 18 | 4 | 4 | API, native config |
| ChatGPT Work and Codex | 18 | 10 | 11 | CLI, native config |
| OpenAI API Platform | 12 | 12 | 18 | Terraform, API, CLI, SDK, Sigma |
| OpenAI Ads | 11 | 8 | 11 | API, native config, SDK, Sigma |
| Ona | 29 | 24 | 52 | Terraform, API, CLI, native config, Sigma |
| Statsig | 13 | 7 | 9 | Terraform, API, CLI, native config, SDK |
| **Total** | **135** | **67** | **107** | Seven guides |

Shared helpers, dependency manifests/locks, provider bootstrap files, READMEs and tests are excluded from numbered pack counts. Original Common, Dots and Ona numbered headings/anchors remain intact. The Common section/type collision, four invented JSON configurations and unsupported historical endpoints/event assumptions were resolved against current evidence; they were not treated as unrelated corpus debt.

Prism is covered as a separate personal-account service with an announced January 1, 2027 shutdown, private export and migration limitations. Frontier's public customer administration and automation contracts remain unverified; common ChatGPT/API policies are not presented as Frontier enforcement. Retired Sora, announced Atlas retirement, Neptune service lifecycle, pending Pierre acquisition and excluded media/business operations have explicit inventory dispositions. Ownership alone never implies shared identity, policy, logs, retention or region settings.

## Executed offline checks

The initial five Bun suites passed together at `f200c1c`: **65 tests, 0 failures, 1,256 assertions**. Tests use synthetic credentials and mocked HTTP/loopback fixtures, never product credentials or a tenant.

| Component | Tests / assertions | Meaningful checks |
|-----------|--------------------|-------------------|
| Common / Dots / Work | 9 / 153 | Compliance pagination, advancing cursor and checkpoint recovery, private file modes, malformed JSONL rejection, trigger/run identity GET, native TOML parse and profile guards, trusted Security dry-run input |
| API Platform | 17 / 125 | Actual SDK serialization and signature verifier, explicit cyber program/no fallback, read-only pagination, saved PSP status, ingress denial, late-failure atomic output, bounded transport and argv privacy, fake-installed CLI guard/redacted single-call staging |
| Ads | 12 / 91 | Actual SDK callback verification, consent wrapper, native field emitters, validation-only conversion payloads, fixed origins, pagination, private staging, argv privacy and response bounds |
| Ona | 16 / 792 | All 20 default packs, documented messages/envelopes, omitted proto3 repeated fields, profile/base restrictions, bounded/redacted credential-safe transport, fanout and pagination failures, complete NDJSON, private exclusive output, explicit write branches |
| Statsig | 11 / 95 | Actual released AutoCapture plugin/metadata builder, authoritative browser URL and query-spoof regressions, fixed read origins, private output, key-metadata minimization, magic-key rejection and CLI fixture |

Official SDK dependencies were installed from isolated frozen Bun locks with lifecycle scripts disabled: `openai` **7.51.0** separately for API and Ads, and `@statsig/web-analytics` **3.33.7** for Statsig. No ambient auto-install or substitute SDK is the verification basis. The Statsig component record also documents the [independent review and correction](/research/statsig-validation/) of the native URL fields and consent-buffering limitations.

API/Ads/Ona transport keeps credentials out of arguments, ignores curlrc, validates destinations, bounds requests and bodies, suppresses raw vendor errors, and withholds partial multi-page evidence on failure. Common/Dots Compliance uses the documented redirected download flow with origin-bound authentication, private files and resumable page checkpoints; completed files can remain after a later failure and must be protected as exported customer data. Caller-created stdout files require a private caller umask. These controls do not establish the completeness of an undocumented vendor schema or production audit mapping.

Terraform formatting passed for all touched modules. The actual pinned API provider **1.5.0** initialized and validated; the actual pinned Statsig provider **2.2.1** initialized, validated and passed **five mocked plans**. No real plan/apply was run. Ona's published **0.5.1** provider offers Linux binaries only; this macOS host has no Docker daemon, so real Ona schema validation is assigned to the Linux CI job for each of the 20 independent recipes. No API/CLI agent or desktop product was installed for validation.

## Structural and rendered checks

The final report below is completed from the generated artifacts and browser observations before publication. The working check tree is a materialized base archive plus SHA-256-recorded authored sources in `/tmp`, avoiding intermittent cloud-placeholder reads in the Documents worktree. It uses the same repository scripts and unchanged unrelated base content; dependency installs and rendered output stay outside the repository. Final commit tree parity is checked before publishing.

- Guide lint: passed, **ALL TESTS PASSED**, zero warnings.
- Pack sync: every vendor generated successfully, with no error marker; only the seven owned generated data files were copied back. Source and generated-data checks passed all 67 includes and 107 unique numbered files. All 135 controls have complete profile/description/rationale anatomy, and original numbered Common/Dots/Ona headings are preserved.
- Real browser: all seven local pages produced 135 control rows and 405 nonempty cells, with 113 code excerpt elements from 107 source files (six Ona files contain two excerpts). The rendered Statsig evidence link was followed successfully to its actual research page.
- Whole-corpus pack validation still reports five pre-existing failure groups outside this family (Bitbucket/Vault collisions, Vault/Docker syntax, extension-table debt and an Azure prose-only Terraform file). The blocking touched-file gate is run against the signed commit before publication; its result is recorded in the PR.
- Local Jekyll uses the already cached Ruby 3.2 gems with a compatible task-local Gemfile/lock and disk cache disabled. CI uses the repository lockfile. Research pages use the repository's real `default` layout.
- Public-site post-deployment verification is **pending maintainer merge and deployment**; a local build of this draft branch is not the public site.

## Remaining validation limits

Follow-up CI diagnosis: the published Ona 0.5.1 provider validated the first 15 independent recipes, then reproduced the previously documented 4.3 unknown-client-ID validation artifact. The [Ona source ledger](/research/ona-source-coverage/#native-provider-validation-follow-up) records the immutable implementation and corrective gate. Six focused gate regressions passed with 38 assertions; all six offline suites passed together with **71 tests, zero failures and 1,294 assertions**. Actionlint and all 11 workflow shell bodies passed. The replacement gate aggregates every recipe, accepts only the precise direct-root diagnostic for 4.3, and requires native positive/empty-ID child-module checks with synthetic literal inputs. Its actual native Linux result remains pending CI; these local fixtures do not establish a vendor schema pass.

Tenant edition/rollout, SSO/SCIM recovery, personal/work identity separation, actual managed requirements across every runtime, cloud versus device policy, connected-service permissions, retention/region enforcement, live audit attribution and production SIEM fields were not exercised. Current public ChatGPT/Dots policy-write schemas, Frontier administration, Prism automation, some partner-specific integration scopes/revocation/replay contracts, and Statsig audit REST/export remain explicit research gaps rather than invented controls or claims of absence. API Admin keys/events do not verify ChatGPT Enterprise policy. No product setting, integration, credential, account or live environment was changed.
