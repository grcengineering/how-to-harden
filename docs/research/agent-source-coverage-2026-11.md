---
layout: default
title: "OpenCode, Hermes, Pi and OhMyPi source coverage — November 2026"
---

# Coding-agent hardening source-first coverage ledger

Research started 2026-11-15; final cited-URL recheck 2026-11-16. Scope: four local agent runtimes and their adjacent managed/configuration, CLI, integration and data surfaces. **No tenants declared — Tier 0+1 only.** No credential source was used, no live agent/tenant was hardened, and no device settings or upstream installations were changed. This is a bounded public-source review and offline test run, not an assertion of unpublished or complete enterprise product coverage.

The repository create-hth-guide, create-code-pack, verify-hth and validate-hth-guide playbooks and shared source/Trust Center discovery instructions were read. Source collection preceded control selection. Unknown surfaces below are retained as gaps, not promoted to verified absence. No `ai-reviewed`, `ai-validated` or human maturity status is claimed.

## Product identity and immutable release pins

| Product | Official project / distribution | Reviewed release | Exact tag commit |
|---|---|---|---|
| OpenCode | [anomalyco/opencode](https://github.com/anomalyco/opencode); `@opencode/cli` | [v2.3.0](https://github.com/anomalyco/opencode/releases/tag/v2.3.0) | `a6b15d33daf6ab7d35569f6d711fdb630b9f04e7` |
| Hermes Agent | [NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent); `NousResearch/hermes-agent` | [v0.23.1](https://github.com/NousResearch/hermes-agent/releases/tag/v0.23.1) | `3b421578588243f920886e6fe79a6faa87ea026e` |
| Pi.dev | [earendil-works/pi](https://github.com/earendil-works/pi); `@earendil-works/pi-coding-agent` | [v1.5.2](https://github.com/earendil-works/pi/releases/tag/v1.5.2) | `b4afdddf44e059c67ccf5097e5317d913521b470` |
| OhMyPi | [can1357/oh-my-pi](https://github.com/can1357/oh-my-pi); `@oh-my-pi/pi-coding-agent` | [v18.20.2](https://github.com/can1357/oh-my-pi/releases/tag/v18.20.2) | `7c49c11aa5bbaf3f418406583096168ad5b8c6dc` |

OpenCode requires care: the first `/releases/latest` response returned V1 v1.19.5, whereas the release list/current installation docs showed V2 v2.3.0. Both products use the `opencode` command. Release-list and tag-commit checks resolved that ambiguity. Current OpenCode policies require 2.2.3 for separate integration/MCP/skill/plugin actions and 2.2.6 for web search; the full pack nevertheless accepts **only 2.3.0**, not every version above those floors. Pi’s historic project-extension advisory floor 0.79.0 is likewise not its pack’s supported-version range. Hermes is the Nous personal agent, not a model or another Hermes package. OhMyPi is independently versioned and does not inherit Pi.dev flags or security guarantees.

Default-branch snapshots used for discovery were OpenCode `5d55571d8d0ea5def971f193dd2d3e7b61eec39d`, Hermes `4162ecf11f611400fa6e5c42d2f360188ce50b39`, Pi `22fc026b872b4a7df22ffa94e8fa00b873128054` and OhMyPi `61311abb5abad892ce4e62dbd78fe06791f20ae8`. Critical policy/managed/CLI/settings references were additionally read from the selected release tags. Public schemas are separately dated snapshots; current schema shape is not release-runtime proof.

## Discovery boundaries and Trust Centers

- **OpenCode:** official enterprise page → [Anomaly Trust Center](https://trust.opencode.ai/), verified from the first-party enterprise link. Public Overview, Policies, Controls, Subprocessors and Documents headings/catalog were inspected. The public page reported six documents; rendered text exposed assurance/contract titles including pentest executive summary, SOC 2 report and DPA variants, marked NDA. No customer secure-implementation document body was publicly verified, no private structured route was guessed, no NDA/access request submitted. Catalog extraction did not establish complete pagination/document enumeration. Restricted bodies remain inaccessible, not absent; no Trust Center assurance item originates a control here.
- **Hermes:** official docs navigation, SECURITY.md and public searches for `"Hermes Agent" "Trust Center"` were checked. No official portal/catalog was identified in that bounded search. The AGA trust page surfaced by search describes a different consuming service and was excluded. Hosted/Business assurance remains outside the local-agent scope and unverified.
- **Pi.dev:** official docs/package index, Earendil project and search for `"pi.dev" "Trust Center"` were checked. No official configuration catalog was identified. Search results about Inflection Pi/other products were excluded. Pi Durable, Radius service administration and GUI applications are adjacent product planes, not silently treated as this CLI’s managed policy.
- **OhMyPi:** official repository documentation tree and search for `"OhMyPi" "Trust Center"` were checked. No official portal/catalog was identified in that bounded search. GitHub’s own Trust Center navigation is not the fork’s security documentation.

Tier 2 searches covered the four product names plus CIS Benchmark, DISA STIG, CISA SCuBA, NSA and ACSC, restricted to their official domains where supported. No product-specific CIS/SCuBA baseline was identified in this search; DISA catalog coverage was not independently established and remains **unverified**, not “no STIG exists.” Generic OS/container benchmarks do not originate invented agent settings. [NIST SP 800-53 Rev. 5](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final) supplies suggested relationships only, not product certification or exact vendor requirements.

Tier 3/4 sweeps included the SOURCES.md standing teams Pluto, PromptArmor, Trail of Bits and Legit Security plus upstream security advisories. Pluto’s TeamPCP agent-configuration persistence research was a discovery/rationale lead, not transcribed into an unverified detection or incident count. The first-party [Pi advisory GHSA-mqxh-6gq7-558m](https://github.com/earendil-works/pi/security/advisories/GHSA-mqxh-6gq7-558m) was body-read and its affected/fixed versions used in Pi 1.1. Automated OhMyPi issue allegations and community comparisons were excluded as authoritative configuration evidence. No new third-party source is needed to originate the shipped controls.

## Source-derived candidates and dispositions

The rows record settings and boundaries identified while reading the official documents, including limitations and deliberately unimplemented candidates. Pack availability is a separate census below.

| Candidate / precise first-party source | Conditions, defaults and limitations | Disposition |
|---|---|---|
| OpenCode [V1 migration](https://opencode.ai/docs/migrate-v1/) and [permissions](https://opencode.ai/docs/permissions/) | V2 arrays, shell/subagent names; V1 and V2 share paths; plugin/API contracts differ | Covered 1.1, 4.1; explicit version gate; no V1 config pack |
| OpenCode [config locations](https://opencode.ai/docs/config/) | System directories; macOS managed preference override; settings cannot prevent new resources | Covered 1.2, 5.1; managed policies plus effective-source negative test |
| OpenCode [policy matching/precedence](https://opencode.ai/docs/policies/) | Last match; default allow if no match; invalid statements dropped with warning; broader authority later | Covered 1.2, 3.1–3.2, 5.1; ordered defaults and startup diagnostics required |
| OpenCode policy provider/integration actions | Separate provider ID, integration connection and account scope; personal #account versus bare provider; Console scope | Covered 3.1; exact direct-provider exception only; organization ID deliberately not fabricated |
| OpenCode policy MCP/skill/plugin/websearch actions | Separate classes since 2.2.3; search floor 2.2.6; package/path identity differs | Covered 3.2, 4.2; all four explicit denies; no inference that integration.use alone restricts them |
| OpenCode [plugins](https://opencode.ai/docs/plugins/) / [MCP](https://opencode.ai/docs/mcp-servers/) | Multiple discovery sources, additive plugin arrays and executable dependency code | Covered 2.1, 3.2; top-level scan clearly not a complete inventory |
| OpenCode [CLI web](https://opencode.ai/docs/cli/web/) | Loopback default, remote consent, one-use five-minute links, 30-day sessions, password invalidation | Covered 2.2, 5.2; no remote exposure or session mutation performed |
| OpenCode [network](https://opencode.ai/docs/network/) | Managed service versus foreground environment, NO_PROXY loopback, CA verification, private service env can disclose proxy secrets | Covered 2.2, 4.2; environment check and external enforcement, no proxy-only containment claim |
| OpenCode snapshots/Console SSO/tenant settings | Distinct data/admin planes; not fully researched or exercised in this local-runtime scope | Gap/outside current implementation: no retention toggle, tenant admin endpoint or universal DLP claim |
| Hermes [SECURITY.md](https://github.com/NousResearch/hermes-agent/blob/v0.23.1/SECURITY.md) §2 | Single-tenant; only OS isolation contains hostile model; terminal backend omits Python/execute_code/MCP/plugins/hooks/skills | Covered 2.1, 3.2; Docker terminal setting is explicitly narrower than full wrapping |
| Hermes [managed scope](https://hermes-agent.nousresearch.com/docs/user-guide/managed-scope) | Root-owned source, fixed bootstrap selector, leaf pinning; malformed file ignored; world-readable managed env | Covered 1.2, 3.1, 5.1; no secret values or permission changes installed |
| Hermes [security approval modes](https://hermes-agent.nousresearch.com/docs/user-guide/security) | Manual only for dangerous-command detector; Docker can skip checks; headless denies; allowlist exceptions and restart memory; YOLO persists | Covered 4.1; no “ask for every tool” assertion |
| Hermes security approval approvers / confirmation keys | [] limits answers to requester/platform administrators; ['*'] admits any admitted member; reload/destructive confirms | Covered 4.1; explicit type/value tests |
| Hermes security skill env / credential files | Skills expand explicit env/file forwarding; read-only mounted credentials remain readable | Covered 3.1–3.2; empty arrays are not claimed sufficient |
| Hermes security gateway authorization | Platform allowlists/pairing; global allow-all config/env bridges and multiple profiles | Covered 2.2; no fake identity API; real roster/pairing remains operator-specific |
| Hermes [API server](https://hermes-agent.nousresearch.com/docs/user-guide/features/api-server) / [dashboard](https://hermes-agent.nousresearch.com/docs/user-guide/features/web-dashboard) | API key required on loopback; full tool reach; narrow CORS; separate public dashboard OAuth/OIDC | Covered 2.2; no server enabled, no keys created; dashboard/operator auth still requires manual verification |
| Hermes [work-machine guide](https://hermes-agent.nousresearch.com/docs/guides/secure-hermes-on-a-work-machine) | write safe root covers write_file/patch only; state roots needed; checkpoints sensitive, rollback preview | Covered 4.2; no write-root or proxy recipe promoted to full containment |
| Hermes remote config backends / package-managed deployment | Deployment and secret synchronization have independent trust requirements | Adjacent gap: do not claim these packs provision Nix, Vault, hosted policy or remote secret backends |
| Pi [security](https://docs.pi.dev/latest/security) trust sequence | No per-tool sandbox; context files load despite decline; sessionDir lookup before trust | Covered 2.1, 4.2; explicit resource flags, no-session and absolute session directory |
| Pi [CLI](https://docs.pi.dev/latest/cli) resource/tool options | Explicit extension/skill paths override discovery disables; tools list alone leaves MCP reachable; no-mcp affects built-in implementation | Covered 3.2, 4.1; fixed launch interface with abbreviation disabled, no arbitrary agent args |
| Pi [settings](https://docs.pi.dev/latest/settings) / [configuration](https://docs.pi.dev/latest/configuration) | Agent-directory trust default; project overrides; resource lists combine; state selectors; model selection is not enforced routing | Covered 1.2, 3.1, 5.1; no managed tenant policy invented |
| Pi [containerization](https://docs.pi.dev/latest/containerization) | Whole-process versus tool-only Gondolin; exposed credentials/network remain accessible | Covered 2.1, 2.2; external boundary remains operator-supplied |
| Pi [packages](https://docs.pi.dev/latest/packages) | Executable package resources and source/version review | Covered 3.2; no package install executed |
| Pi CLI credential commands | auth check structured result; --no-refresh available; credential-print switches expose secrets | Covered 3.1, 5.2; fixed opt-in read omits credential-print switches |
| Pi session sharing / user GUI / SDK hosts | Retention/sharing and embedding can create distinct surfaces | Covered 4.2 for local evidence governance; Radius/Durable/GUI admin and embedded SDK enforcement unverified/out of current pack scope |
| OhMyPi [settings](https://github.com/can1357/oh-my-pi/blob/v18.20.2/docs/settings.md) precedence | Global < project < overlays < env < runtime; arrays replace; live invalid layers can retain last good | Covered 1.2, 5.1; no immutable org-policy claim |
| OhMyPi [approval modes](https://github.com/can1357/oh-my-pi/blob/v18.20.2/docs/approval-mode.md) | Default YOLO; explicit per-tool deny/prompt; eval alternate shell; restrictedFolders shell cwd; headless subagents YOLO | Covered 4.1; explicit eval/task/computer denies and negative-test plan |
| OhMyPi approval cache / computer.control | Optional persistent grants; restricted folders not path containment; separate foreground control grant | Covered 2.2, 4.2, 5.2; no grants cleared on a real device |
| OhMyPi settings provider/source disabling | enabledProviders is foreign discovery, not model allowlist; disabledProviders shared namespace; project replacement | Covered 3.1; no finite model blocklist advertised as exclusive routing |
| OhMyPi [MCP settings source](https://github.com/can1357/oh-my-pi/blob/v18.20.2/packages/coding-agent/src/mcp/settings.ts) / discovery | Project config switch leaves native user MCP; foreign configuration and profile roots | Covered 2.1, 3.2; user/home/source inspection remains necessary |
| OhMyPi [secrets](https://github.com/can1357/oh-my-pi/blob/v18.20.2/packages/coding-agent/src/secrets/settings.ts) / [telemetry](https://github.com/can1357/oh-my-pi/blob/v18.20.2/packages/coding-agent/src/telemetry-settings.ts) registry | Secret obfuscation default false; OTLP export default true and next-launch change | Covered 4.2; independent source registry keys, not inferred from Pi |
| OhMyPi auth broker/gateway, collab/browser services and SDK embedding | Separate authenticated services, credentials, host environment and runtime overrides | Partially covered by 2.2/3.1 review; no auth-broker deployment, collab tenant policy or SDK enforcement pack claimed; full service-specific review remains a gap |

## Six-surface automation census

“Not identified” is bounded to the first-party indexes/source tree examined, not proof of universal absence. All shipped handles are available in the reviewed references; no deprecated handle is required. Runtime APIs/SDKs are not presumed to be managed security administration.

| Product | Terraform resource / data source | REST / GraphQL | First-party CLI read / write | SDK | Native configuration | SIEM |
|---|---|---|---|---|---|---|
| OpenCode | No vendor managed-policy provider identified; independent registry coverage unverified | Local server API documented; no managed-file write/GraphQL contract verified for these controls | `--version`, `service status` reads shipped; debug config/source review documented; service setters are writes and not executed | Typed client/runtime SDK exists; no fleet policy API verified | System/managed policy JSON and permissions are the shipped candidate surface | Local diagnostics; no stable tenant audit-export contract verified; no fabricated SIEM events |
| Hermes | No managed-scope provider identified; registry absence not asserted | API server chat/run/session/tool interfaces read; not a fleet managed-file API; GraphQL not identified in those refs | `--version`, `doctor` shipped; config/set, pairing, plugin and gateway writes documented but not executed | Python plugin/agent APIs are executable extension surfaces, not verified fleet admin methods | Managed YAML/JSON, approval/env/credential controls shipped as candidates | Local diagnostics/session data; no complete normalized tenant audit schema verified |
| Pi | No official provider identified; registry coverage unverified | RPC/JSON integration interface, not a verified managed tenant REST/GraphQL policy plane | `--version`, `auth check --json --no-refresh` shipped; package/auth writes exist and are not run | Official createAgentSession/runtime SDK exists; caller owns enforcement; no admin SDK invented | Agent settings JSON plus fixed CLI resource flags shipped | JSON/session stream exists; no stable security-event export or tenant admin audit corpus asserted |
| OhMyPi | No provider identified in official docs; registry coverage unverified | RPC/ACP and optional broker/gateway interfaces exist; no managed organization policy REST/GraphQL schema verified | `--version`, typed config get reads shipped; config set/reset writes documented, not run | Runtime/plugin SDK exists with overrides; not an immutable management plane | Typed YAML/JSON settings, final overlay and approval map shipped | OTLP exporters and local evidence exist; no invented security-event schema or detection query |

Each guide has **10 controls with a pack** and **two shipped types** (`config`, `cli`). Config candidates and CLI verification cover their real interfaces; a third nominal type is not fabricated to improve a diversity count. Read/audit code is distinct from candidate emitters. No candidate is installed; no native setter is invoked. The CLI inventory has four new rows with the precise local/runtime versus tenant-admin distinction.

## Retrieval evidence and failures

Public docs were read through web extraction and first-party raw GitHub snapshots. Final cited URLs were re-fetched with a browser user agent and content-specific title/body identity on 2026-11-16; these are **DRIFT-CHECKED-ONLY**, never live-validation passes. SHA-256 records of downloaded public sources were kept in temporary research artifacts. Native schema snapshots and their hashes are committed with the fixtures for offline reproducibility.

Initial fetches of an assumed OpenCode `cli/paths.mdx`, Hermes `messaging.md`/`hermes-docker.md` and OhMyPi `docs/cli.md` returned 404. They were not treated as missing capabilities: the documentation trees were inspected, supported references selected, and no failed path is cited by a guide. The default fetcher got 403 from `opencode.ai/config.json` and `models.dev/model-schema.json`; a browser-user-agent retry returned the actual schema body, cached for tests. The latter is an explicit dependency of the former and is resolved offline during tests. Direct ordinary network access in the workspace was unavailable; approved public reads were used without executing fetched code.

| URL | Retrieval result / content identity |
|---|---|
| https://docs.pi.dev/latest/cli | 200; Command Line · Documentation · Pi; 127680 bytes |
| https://docs.pi.dev/latest/configuration | 200; Configuration · Documentation · Pi; 49554 bytes |
| https://docs.pi.dev/latest/containerization | 200; Run Pi in an isolated environment · Documentation · Pi; 110090 bytes |
| https://docs.pi.dev/latest/packages | 200; Pi Packages · Documentation · Pi; 78013 bytes |
| https://docs.pi.dev/latest/security | 200; Run Pi safely · Documentation · Pi; 64435 bytes |
| https://docs.pi.dev/latest/settings | 200; Settings Reference · Documentation · Pi; 88333 bytes |
| https://github.com/NousResearch/hermes-agent/blob/v0.23.1/SECURITY.md | 200; hermes-agent/SECURITY.md at v0.23.1 · NousResearch/hermes-agent · GitHub; 276207 bytes |
| https://github.com/can1357/oh-my-pi/blob/v18.20.2/README.md | 200; oh-my-pi/README.md at v18.20.2 · can1357/oh-my-pi · GitHub; 570371 bytes |
| https://github.com/can1357/oh-my-pi/blob/v18.20.2/docs/approval-mode.md | 200; oh-my-pi/docs/approval-mode.md at v18.20.2 · can1357/oh-my-pi · GitHub; 314752 bytes |
| https://github.com/can1357/oh-my-pi/blob/v18.20.2/docs/config-usage.md | 200; oh-my-pi/docs/config-usage.md at v18.20.2 · can1357/oh-my-pi · GitHub; 387063 bytes |
| https://github.com/can1357/oh-my-pi/blob/v18.20.2/docs/mcp-config.md | 200; oh-my-pi/docs/mcp-config.md at v18.20.2 · can1357/oh-my-pi · GitHub; 443259 bytes |
| https://github.com/can1357/oh-my-pi/blob/v18.20.2/docs/settings.md | 200; oh-my-pi/docs/settings.md at v18.20.2 · can1357/oh-my-pi · GitHub; 1113907 bytes |
| https://github.com/can1357/oh-my-pi/blob/v18.20.2/packages/coding-agent/src/secrets/settings.ts | 200; oh-my-pi/packages/coding-agent/src/secrets/settings.ts at v18.20.2 · can1357/oh-my-pi · GitHub; 200011 bytes |
| https://github.com/earendil-works/pi/security/advisories/GHSA-mqxh-6gq7-558m | 200; Pi loads project-local extensions without approval · Advisory · earendil-works/pi · GitHub; 156706 bytes |
| https://hermes-agent.nousresearch.com/docs/guides/secure-hermes-on-a-work-machine | 200; Running Hermes on a Personal or Work Machine | Hermes Agent; 60756 bytes |
| https://hermes-agent.nousresearch.com/docs/user-guide/cli | 200; CLI Interface | Hermes Agent; 136748 bytes |
| https://hermes-agent.nousresearch.com/docs/user-guide/features/api-server | 200; API Server | Hermes Agent; 186154 bytes |
| https://hermes-agent.nousresearch.com/docs/user-guide/features/plugins | 200; Plugins | Hermes Agent; 269046 bytes |
| https://hermes-agent.nousresearch.com/docs/user-guide/managed-scope | 200; Managed Scope | Hermes Agent; 48675 bytes |
| https://hermes-agent.nousresearch.com/docs/user-guide/security | 200; Security | Hermes Agent; 197832 bytes |
| https://opencode.ai/docs/cli/commands/ | 200; Commands | OpenCode; 144249 bytes |
| https://opencode.ai/docs/cli/web/ | 200; Web | OpenCode; 54414 bytes |
| https://opencode.ai/docs/config/ | 200; Config | OpenCode; 154743 bytes |
| https://opencode.ai/docs/mcp-servers/ | 200; MCP servers | OpenCode; 144787 bytes |
| https://opencode.ai/docs/migrate-v1/ | 200; Migrate from V1 | OpenCode; 134040 bytes |
| https://opencode.ai/docs/network/ | 200; Network | OpenCode; 64687 bytes |
| https://opencode.ai/docs/permissions/ | 200; Permissions | OpenCode; 97159 bytes |
| https://opencode.ai/docs/plugins/ | 200; Plugins | OpenCode; 66787 bytes |
| https://opencode.ai/docs/policies/ | 200; Policies | OpenCode; 100913 bytes |

## Verification and evidence limits

- **Offline behavioral tests:** candidate/schema validation, malformed/duplicate/alias/type rejection, wildcard/order policy drift, alternate execution/credential expansions, non-executing launch plans, secret-safe errors and fake native executable tests. See `scripts/test-agent-hardening-packs.py`.
- **Repository verification:** content lint, guide/parser parity, pack sync and per-vendor/touched validation, aggregate local tests and strict Jekyll build are recorded in the PR validation evidence; corpus-wide pre-existing findings are reported separately.
- **Live product/tenant proof:** NOT RUN by scope. No real agent binary, remote inference, gateway user roster, server exposure, OS isolation, credential injection, restoration or policy denial was exercised. Each guide remains `ai-drafted`.
- **OCEAN:** no new deprecated HTH scanner-control YAML is authored. OCEAN checks/live conformance were not needed to run these local fixture packs and are not claimed; tenant-bound checks are NOT RUN. No OCEAN harden/apply command is issued.
- **External tool limits:** CodeGuard MCP rule tools were not exposed in this session, so no invocation is claimed. The authoring rules, explicit input/privacy boundaries and offline adversarial tests are the available checks. CocoIndex indexing/search was used to inspect existing repo conventions; it is not security validation.
- **Deployment spot check:** a draft PR does not publish guide pages to the live site. Local generated HTML is checked; production `/guides/.../?view=cheat` verification remains NOT RUN until the user reviews/merges/deploys.

Remaining evidence gaps are the inaccessible/partially enumerated Trust Center bodies, unverified product-specific DISA/provider/admin surfaces, adjacent hosted/broker/SDK administration, and all live enforcement results. These do not justify inventing configuration or upgrading maturity.
