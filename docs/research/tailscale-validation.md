# Tailscale local verification report

Date: **2026-11-04 UTC**. Branch: `feat/tailscale-hardening-guide`. Base: `bf8172c` (`origin/main` when the isolated checkout was prepared). Subject: the standalone Tailscale guide, eighteen controls and 27 source packs across six implementation types.

**No tenants declared — Tier 0+1 only.** `VERIFIED-LIVE = 0`. The guide remains exactly `["ai-drafted"]`; no live-validation or review badge was added. During this local verification stage, no push, publication, pull request, Tailscale setting change, node enrollment, credential creation or credentialed product request occurred.

## Results

| Check | Result | Evidence and practical limit |
|-------|--------|------------------------------|
| Guide lint | PASS | `bash scripts/validate-guides.sh`: `ALL TESTS PASSED (0 warnings)`. |
| Tailscale offline boundary tests | PASS | 36 Python tests with fake curl/CLI; no product request. Tests exercise transport, candidate validation, schema errors, privacy, profiles, exclusive output, metadata collection and policy generation. |
| Shell compatibility | PASS | The final 36-test suite passed under both macOS Bash 3.2 and Homebrew Bash 5, including the error-output privacy regression. |
| SDK compile and tests | PASS, LOCAL SOURCE FALLBACK | Seven top-level Go tests, including malformed/duplicate/partial response subcases, compile against the real pinned SDK and production dependencies using a separate local-replacement modfile. Fake HTTP only. Normal module-proxy installation did not succeed. |
| Existing regression suites | PASS | Cognition: 42 API, 17 CLI, 25 Desktop and 20 DeepWiki tests; Factory: 34 tests. 138 existing tests passed. |
| ShellCheck | PASS | Exit 0 for all Tailscale shell control files and both helpers with `shellcheck -x -P SCRIPTDIR`. No warning suppression added. |
| Native source whitespace | PASS | Staged native source passes `git diff --cached --check`. The unchanged canonical generator emits 18 indented blank lines and one final blank line in the new YAML, which Git reports as whitespace findings; the generated file is retained byte-for-byte rather than hand-edited. |
| Terraform formatting | PASS | `terraform fmt -check -recursive` exits 0, including the ten mocked-provider safety plans. This is syntax/format evidence, not provider schema proof. |
| Terraform schema / mocked plans | SKIPPED — DEPENDENCY ABSENT | `terraform validate` reports the missing `tailscale/tailscale` provider. `terraform test` reports unknown provider and executes zero plans. Registry discovery timed out; the official 0.29.3 GitHub release-asset download also failed its TLS handshake. No Terraform plan or apply reached a tailnet. |
| Structural/parser wiring | PASS | 18 complete leveled controls, 17 includes and one evidenced upstream-MFA manual verdict; 27 nonempty generated pack entries across API/CLI/config/Terraform/SDK/SIEM; zero guide fences or status marks. |
| Full canonical pack sync | PASS | All 91 vendors emitted success markers in the full sync. Tailscale emitted 27 files into 17 sections. The generator itself is unchanged. |
| Unrelated generated data | PASS | The 90 existing vendor files differed only in the generator timestamp; their original bytes were restored. No unrelated generated-data change is retained. |
| Actual changed-files gate | PASS | `bash scripts/validate-packs.sh --touched` exited 0 against source commit `e721c0f`, gating 37 changed guide/pack files: `No failures in the files this branch touched.` |
| Full pack corpus | BASELINE DEBT | The full report has the same five failure groups and twenty underlying failure records as the clean base. No Tailscale finding appears. Exact touched-branch gate is recorded in the close-out below. |
| Cached Jekyll build | PASS | Final strict-front-matter build succeeds with Jekyll 4.4.1, `--disable-disk-cache` and a separate cache-compatible task-local lockfile. The committed dependency files are unchanged. A redundant cache-enabled attempt stalled reading Marshal cache data and was interrupted; the uncached render completed in 56.523 seconds. |
| Desktop/mobile Chromium | PASS | 18 populated cheat-sheet rows, 27 nonempty pack/source blocks, working anchors and jump navigation, catalog entry, no page errors. Desktop 1440×1000; mobile 390×844 with document width 390. All browser requests were restricted to localhost. |
| Committed-lockfile build | SKIPPED — EXACT GEMS ABSENT | The existing gem cache lacks `json 2.19.9` and `concurrent-ruby 1.3.7`; the cache-compatible build uses 2.19.5 and 1.3.6. No lockfile or TLS verification setting was weakened. |
| OCEAN check templates | PASS | Existing release binary capability-probed; `ocean build --validate --source .../checks` reports `Validated 197 check(s) — templates OK`. No generation, scan or remediation. |
| OCEAN Tailscale module conformance | SKIPPED | No new Tailscale scanner/module or deprecated HTH control-YAML definition was requested or added. No live credential mapping was declared. |
| Live ClickOps / IdP / client / SIEM behavior | SKIPPED | No authorized test tailnet, managed pilot device, IdP, logging destination or credential source was declared. All eighteen controls are documentation-level `DRIFT-CHECKED-ONLY`. |
| CodeGuard MCP | UNAVAILABLE | No CodeGuard MCP tools were enabled. Bundled guidance and actual repository/transport checks were applied; no MCP scan result is claimed. |

## What the tests establish

The shell tests enforce the fixed API origin, HTTPS and normal certificate verification, no redirect following, bounded transport, no token in process arguments, read-only CLI selection, profile validation, complete-result collection and exclusive 0600 output. They reject malformed or unexpected pagination envelopes, missing/duplicate identities, later-read failures and private vendor/schema errors without preserving a partial result.

Candidate-validation tests distinguish an empty HTTP 200 from a nonempty HTTP 200 error response and confirm that only `/acl/validate` can receive a POST. Snapshot tests preserve raw HuJSON and ETag. Native-policy checks reject conflicting/injected identity inputs and verify narrow grants, negative tests, empty legacy ACLs, named SSH accounts and posture conditions. These tests do not execute Tailscale’s policy engine.

SDK tests exercise the maintained official client through a constrained fake HTTP transport, including unexpected origin/method, redirects, response bounds, missing device state, duplicate IDs, private output and invalid inputs. The compilation fallback uses official Git checkouts at the pinned revisions documented in [source evidence](tailscale-source-evidence.md). It changes neither the committed `go.mod` nor the production API origin. A normal `go mod download` with the standard proxy/checksum workflow remains unproven in this environment; no checksum database was disabled.

The Terraform test file contains ten mock-provider plans for empty defaults, device-approval/Lock acknowledgment, update independence, L2 gates, key-period range and IPv4/IPv6 default-route rejection. They are useful runnable follow-up checks, but **none executed here** because the actual provider could not be installed. Fetched official provider documentation and implementation were used for the schema review. No binary with an unverified checksum was executed as a workaround.

## Baseline debt retained

The clean-base and full final pack reports contain identical failure records:

1. Three existing `(section,type)` collisions: Bitbucket config 4.3, ChatGPT Enterprise API 6.6 and HashiCorp Vault CLI 5.2.
2. Existing Bash syntax failure in the HashiCorp Vault authentication pack.
3. Existing Bash syntax failure in the Docker Hub cosign pack.
4. Eleven existing extension/type violations across HashiCorp Vault, Tableau, Wiz and Azure DevOps.
5. One existing pack with no executable content.

Schema migration and automation-coverage warnings remain visible. They were neither suppressed nor repaired as unrelated work. No global validator was narrowed, no pack was removed to hide a failure, and no generated YAML was hand-edited.

## Rendering and evidence

The local cached build proves Liquid, Markdown and pack rendering under the available dependencies. It is not a committed-lockfile build result. Chromium checks confirm fully populated cheat-sheet cells, guide anchors, source links, jump navigation, catalog inclusion and mobile width. Screenshots, browser JSON, raw command logs, structure counts, source snapshots and the baseline comparison are in the task’s sibling `research/` and `render-validation/` directories.

The original working checkout at `~/Code/grcengineering/how-to-harden` has unrelated edits. It was read only; all authoring occurred in the task-local isolated checkout. Existing Factory/Cognition guides, source packs and UI animation files are unchanged. The guide registry was regenerated from all frontmatter; README totals are 138 guides and 91 vendor pack directories.

## Remaining proof

When the pinned provider is available, run `terraform init -backend=false`, `terraform validate` and `terraform test` in `packs/tailscale/terraform/` before treating the Terraform examples as provider-tested. Reproduce the standard Go module install and the Jekyll build using the unchanged committed lockfile when their exact dependencies are reachable.

Live validation requires an explicitly authorized test environment and independently proven recovery access before access-policy, expiry, enrollment or route changes. Test the selected IdP offboarding event; device-approval/Lock choice; actual client/posture behavior; complete merged policy and negative paths; routed/external/Funnel exposure; and fresh destination log delivery. None is implied by a mock, an inventory or a successful template render. Re-stamp the guide’s dates if publication occurs on a later day.

## Local commit close-out

Source commit: `e721c0f223870f9ee6eef3192c6d6624c8a4985c` (`Add Tailscale hardening guide and code packs`), with an SSH signature from the existing configured signer. The initial sandboxed signing attempt could not connect to the signer socket and created no commit; the authorized local retry succeeded. Signing was not disabled.

The actual `bash scripts/validate-packs.sh --touched` run exited **0**, gated **37 changed guide/pack files**, and ended `No failures in the files this branch touched.` Its five full-corpus failure groups and twenty underlying records exactly match the clean baseline. The validator and generator are unchanged. All 90 unrelated generated vendor files retain their original bytes.

This report was saved in a separate local documentation commit after the source gate, without changing the tested guide, packs, generated Tailscale YAML or test code. That verification stage finished before branch publication or pull request creation. The original dirty checkout remains untouched.
