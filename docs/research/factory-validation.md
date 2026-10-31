# Factory verification report

Date: 2026-10-31 UTC. Subject: the standalone Factory guide, 19 controls, and 23 source packs across native configuration, REST, CLI and the official Python SDK.

Branch: `feat/factory-hardening-guide`. Verified base: `761bd5165d8323d61efba7e8392c35b0d2d74d15` (`origin/main` when the isolated checkout was prepared). Signed source commit: `ac97a96` (`Add Factory hardening guide and code packs`). This report is local review evidence; no push, PR, merge, deployment or live Factory configuration change was performed.

## Results

| Check | Result | Evidence and limits |
|-------|--------|---------------------|
| Guide lint | PASS | `bash scripts/validate-guides.sh`: `ALL TESTS PASSED (0 warnings)`. |
| Factory offline regression tests | PASS | `python3 scripts/test-factory-packs.py`: 34 tests passed, using fake curl, Droid and SDK implementations. No product requests or model calls. |
| Existing Cognition regression tests | PASS | `make test-cognition-packs`: 42 API, 17 CLI, 25 Desktop and 20 DeepWiki tests passed (104 total). Together with Factory: 138 tests. |
| ShellCheck | PASS | Exit 0 for the 13 Factory shell files, including helpers, using `shellcheck -x -P SCRIPTDIR`. |
| Guide/parser and pack wiring | PASS | 19 complete leveled controls; 16 pack includes; 3 evidenced manual verdicts; 23 generated pack entries across API, CLI, config and SDK; zero guide fences or live-validation marks. |
| Version/date/registry | PASS | `0.1.0`, `ai-drafted`, and `2026-10-31` agree between guide metadata, changelog and the regenerated registry. Corpus totals: 137 guides, 90 vendor pack directories. |
| Full canonical pack sync | PASS | All 90 vendors emitted a success marker and none emitted a failure marker. Factory was refreshed with the unchanged generator function after the final additions: 23 files into 16 sections. |
| Generated-data preservation | PASS | The 89 other vendors' regenerated files differed only in the `Generated` timestamp. Their original bytes were restored; no unrelated generated-data changes remain. |
| Full pack corpus | BASELINE DEBT | Exit 1, with exactly the same five failure groups and underlying findings as the clean base. Zero introduced failure groups and zero Factory failures. |
| Touched-file pack gate | PASS | Actual `bash scripts/validate-packs.sh --touched` against signed source commit `ac97a96`: exit 0, `No failures in the files this branch touched.` The full underlying report retained the five baseline failure groups. |
| Cached Jekyll render | PASS | Strict-front-matter build exited 0 with existing Jekyll 4.4.1 tools. This used a separate cache-compatible lockfile, not the committed lockfile. |
| Browser rendering | PASS | Local Chromium checks: 19 fully populated cheat-sheet rows, 3 profile groups, 23 nonempty pack blocks/source links, valid guide anchors and jump navigation, Factory in the site catalog, no page errors. Desktop 1440×1000; mobile 390×844 with document width 390 and no page overflow. |
| OCEAN template schema | PASS | Existing OCEAN release binary capability-probed; `ocean build --validate --source .../checks` reported `Validated 197 check(s) — templates OK`. No generation or live scan. |
| Committed-lockfile Jekyll build | SKIPPED | Missing exact gems `json 2.19.9` and `concurrent-ruby 1.3.7`. A public RubyGems connection probe failed with curl exit 28 after its 10-second connection bound. The committed Gemfile and lockfile are unchanged. |
| Live Factory/IdP/device proof | SKIPPED | No tenants declared — Tier 0+1 only. No Factory credential source, test organization, IdP or managed pilot host was declared. |
| OCEAN Factory module/credential conformance | SKIPPED | This change adds no Factory scanner/module or deprecated HTH control-YAML definitions; no live OCEAN credential mapping was declared. |
| Optional CodeGuard MCP | UNAVAILABLE | No CodeGuard tools were enabled in this environment. No CodeGuard scan result is claimed; repository checks and manual source/interface review were used. |

## What the offline tests exercise

- Credential and origin validation before requests, HTTPS-only GET transport, no redirect following, and bearer credentials passed through curl stdin rather than command arguments.
- Complete cursor pagination, encoded cursor values, duplicate records, missing/repeated cursors, page bounds, malformed responses, later-page errors and rejection of partial evidence.
- Private 0600 evidence, refusal to overwrite files or symlinks, temporary-file cleanup, and suppression of response/CLI/SDK error content from console output.
- Strict JSON inputs for source IPv4 ranges, model approvals and telemetry endpoints; rejection of unrestricted `/0`, IPv6 in the source-IP policy, duplicate/empty model lists and credential-bearing collector URLs.
- Literal telemetry credential references, content export disabled, separate image-model governance, tested command-rule file extraction, and distinct candidate/resolved previews without treating exit 0 as policy enforcement.
- Read-only CLI command selection and SDK catalog discovery without starting a model task; drift and unknown outcomes are not converted into compliant results.

Mocks test our code's handling of the documented contract. They do not establish that a tenant has a feature, that a CLI rollout is activated, that a policy field loads on a device, or that an API accepts a real credential.

## Baseline comparison

The clean-base and final reports have identical failure groups and identical underlying records:

1. Three pre-existing `(section,type)` collisions: Bitbucket config 4.3, ChatGPT Enterprise API 6.6, and HashiCorp Vault CLI 5.2.
2. HashiCorp Vault CLI authentication pack fails Bash syntax.
3. Docker Hub CLI cosign pack fails Bash syntax.
4. Eleven pre-existing extension/type violations in HashiCorp Vault, Tableau, Wiz and Azure DevOps.
5. One pre-existing pack with zero executable content.

The pre-existing schema/migration and coverage warnings were retained. Factory's final coverage is **16/19 controls**, with manual verdicts for domain/SSO setup (1.1), SCM installation/credential association (3.4), and managed connector availability (3.5). No invented interface was used to fill those gaps.

Git's additional whitespace inspection notes three formatting warnings in the new generated YAML: padded blank lines inside the SDK excerpt and the generator's blank final line. They are canonical output of the unchanged sync pipeline; freshness comparison passes. Executable source files have no reported whitespace defect. The generated file was not hand-edited or excluded from the repository validators.

## Render and dependency distinction

The successful local render uses a separate task-local Gemfile/lockfile copied from the existing working cache, with the original vendor cache read as a dependency source. The cache contains `json 2.19.5` and `concurrent-ruby 1.3.6`; the committed lockfile requires `2.19.9` and `1.3.7`. This is useful evidence of Liquid, Markdown, excerpt and browser behavior, and is not a locked-dependency build result.

To close the locked-build gap, make those exact gems available and run `cd docs && bundle exec jekyll build --strict_front_matter` using the unchanged committed lockfile. No dependency, signing or TLS security setting was weakened. The first sandboxed signed-commit attempt could not access the local 1Password signing socket; the normal signed commit succeeded with the required local-agent access, and signing remained enabled.

## Live status and remaining proof

All 19 controls were checked against current official documentation: **DRIFT-CHECKED-ONLY**. **VERIFIED-LIVE: 0**. Live ClickOps, IdP behavior, API authorization, resolved client policy, OS sandbox enforcement, connector availability and telemetry delivery remain unexecuted. No `ai-validated`, `ai-reviewed` or human status was added; the guide remains exactly `["ai-drafted"]`.

Before applying configuration, validate the complete merged policy through Factory's supported management workflow and prove behavior on the actual client release. In particular, a malformed system-managed file resolves to empty org policy; a JSON parse is not a schema/enforcement test. Source-IP policies need a verified independent recovery path. Template generation, historical settings snapshots and catalog collection do not establish effective organization/device enforcement.

The original checkout's dirty branch and existing edits were preserved. The Cognition checkout and homepage animation/UI files were not changed. Supporting raw logs, browser results and screenshots are in the task's sibling `research/` and `render-validation/` artifact directories. The source-to-control matrix and current interface limits are in [factory-source-evidence.md](factory-source-evidence.md).
