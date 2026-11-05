# SpaceXSI refresh validation — 2026-11-05

Scope: the historical `spacexai` family at base `99eaa3d1a38ce28ed421ac4020e37e898ea98c9e`. Current naming and product-plane decisions are in [the source reconciliation](spacexai-source-coverage.md), with a separate [Build reconciliation](grok-build-source-coverage.md).

**Tier 0+1 only. No tenants declared; VERIFIED-LIVE = 0.** Documentation reads, synthetic transports, local parsing and provider schema validation do not establish tenant enforcement. All seven guides remain `ai-drafted`. No product sign-in, setting, credential, integration, Terraform plan/apply/import or real agent execution occurred.

## Coverage

| Guide | Leveled controls | Include tags | Numbered pack files | Static rendered pack groups / code excerpts |
|---|---:|---:|---:|---:|
| Cursor / Common Controls | 34 | 24 | 24 | 27 / 38 |
| Grok Bot | 27 | 17 | 30 | 28 / 44 |
| Grok workspace | 9 | 0 | 0 | 0 / 0 |
| Grok API | 11 | 4 | 4 | 4 / 4 |
| Grok Build | 9 | 8 | 9 | 9 / 9 |
| Cursor Cloud Agents | 10 | 2 | 2 | 2 / 2 |
| Cursor Origin | 9 | 5 | 7 | 7 / 7 |
| **Total** | **109** | **60** | **76** | **77 / 104** |

Baseline: two guides, 48 controls, 53 numbered packs, 40 include tags. Result: five new guides, 61 additional controls, 23 additional packs and 20 additional include tags. Helpers, READMEs and Terraform provider/variable files are excluded from numbered-pack totals. A rendered include can contain several pack types and several marked regions; Cursor also retains its existing GitHub pack include. These measures are not interchangeable.

## Completed checks

- `bun test ./scripts/test-spacexai-refresh-packs.ts ./scripts/test-grok-build-packs.ts`: **27 passed, 0 failed, 364 assertions**. Tests cover transport/redirect/target restrictions, response redaction, typed schema drift and pagination, authoritative team identity, partial evidence returning UNKNOWN, native TOML parsing and policy-input injection, opt-in native read commands and private partial output. New Bash wrappers are actually executed without credentials, proving they reach the helper's structured UNKNOWN precondition before network access. Synthetic fixtures do not prove a live API response. Additional private curl-fixture tests verify the Bot helper's fixed HTTPS origin, explicit synthetic-only loopback escape, rejected unsafe credential/path representations, first-argument `-q`, request/size limits, no redirect forwarding and suppressed error bodies; they inspect invocation semantics rather than asserting a live TLS exchange.
- `bash scripts/validate-guides.sh`: **all tests passed, 0 warnings**. Additional local source checks found canonical profile labels, nonempty Description and Rationale sections, and no fenced code in all seven guides. Existing control numbers and anchors remain intact.
- `bash scripts/sync-packs-to-data.sh`: completed. Unrelated files were restored only after confirming their sole difference was the generated timestamp. Full pack validation confirmed fresh generated YAML, reachable marked packs, no unresolved pack anchors or dead includes, and no declared-mode contradictions.
- `bash scripts/validate-packs.sh --all`: **5 existing failure groups, 6 warnings**, with no failure attributed to this lane. Existing failures are three section/type collisions (Bitbucket, ChatGPT Enterprise, HashiCorp Vault), two Bash syntax files (HashiCorp Vault and Docker Hub), 11 extension/type violations in other families, and one prose-only Azure DevOps Terraform file. The post-commit `--touched` gate passed on **66 relevant changed files**, with no failures in this branch's files.
- Native `cursor/cursor` **0.8.0** provider initialization and `terraform validate` passed for both Origin and Cloud Agents, using Terraform 1.17.1 and an isolated empty CLI configuration with vendor credential variables absent. Provider installation reported developer signing key `5E389DAC0B402A90`. Formatting passed. No provider configure, plan, apply or import ran. This verifies the provider's schema, not actual tenant authorization, policy effects or recovery access.
- Local Jekyll build passed using the existing cached Ruby 3.2 bundle and a separate validation Gemfile. The repository's Gemfile/lockfile were unchanged; CI's locked dependency installation remains separate evidence.
- Static parsing of the built HTML found the expected 109 full-guide profile records, 77 rendered pack groups and **104 nonempty code excerpts**, with **no broken guide/fragment links** from the seven guides. This is static HTML evidence only.
- OCEAN `build --validate` passed **197 checks** against the existing canonical checks repository. No OCEAN check or schema file changed in this lane. The staged source diff passes whitespace checks when generated pack YAML is excluded. The generator emits indented empty lines and a final blank line in new YAML files, so an unrestricted staged `git diff --check` reports those canonical generated lines. They were preserved to maintain exact generator freshness; no global generator behavior changed.
- The dedicated [SpaceXSI Pack Safety workflow](../../.github/workflows/spacexai-safety.yml) runs the two explicit Bun suites for changes to their test files, these pack directories or the workflow. A two-product matrix runs Terraform **1.17.1** format/init/validate with the native **cursor/cursor 0.8.0** constraint, empty Terraform CLI configuration and no vendor credentials. It runs no plan/apply/import. Permissions are `contents: read`, checkout credentials are not persisted, and each job has a ten-minute bound. Local `actionlint` passes; both Bun suites still report **27 passed / 364 assertions**. The existing shared Test workflow did not run these suites; it remains unchanged. Remote run results belong to the PR handoff, separate from local evidence.

## Browser limitation

The local preview served successfully on loopback. Interceptor's first `tab_create` timed out; a subsequent group read confirmed no attached tabs. A second `tab_create` also timed out without a successful attached-tab result. No shared daemon or browser settings were changed. The CUA fallback reported `browsers: []`, and creating a hidden IAB tab returned **“Browser is not available: iab”**.

Consequently, interactive cheat-sheet row/cell parity, expanded-pack interaction, clipboard/download behavior, responsive layout and screenshots remain **unverified in a live browser**. Static code/excerpt/link checks do not replace those checks. Existing user tabs and application focus were preserved.

## Source and execution limits

Current first-party documents support separate Cursor, Bot, Grok workspace, API, Build, Cloud Agent and Origin authority planes. They do not establish inherited Cursor policy for a Grok API/workspace tenant. Full X social/account/developer and standalone X Chat administration remain uncovered external operational scope, with no existing X/Twitter guide in this base; current Grok FAQ distinguishes X operations from SpaceXSI. The AI integration's developer-account creation, personal-only Bot linking, separate training setting and AI group-message exposure are covered. Grokipedia administration, negotiated government/partner deployment settings, SIP-specific hardening, hosted Build publication details and a completed Graphite acquisition remain explicit source gaps or external deployment boundaries. Some new native controls are beta, rollout-dependent or Enterprise-only. The provider's registry web page/latest-release state was not established; exact-version native initialization and developer-signature verification did pass, alongside first-party GitHub source and installed-schema reads.

No pack's metadata inventory, configuration candidate, read-only output or successful local test is whole-control compliance. Bot checks with an unobservable surface return UNKNOWN/exit 3. The destructive offboarding pack requires authoritative team-ID proof and retains the computer/disk-only deletion action; the newly documented broader Bot-data erase is described separately in the guide.
