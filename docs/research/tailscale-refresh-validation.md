# Tailscale refresh verification

Date: **2026-11-05 UTC**. Branch: `update/tailscale-source-coverage`. Base: `ab1d56a13983f98774c25ca3ac8d8bea754bd14f`, which already contains merged skills PR [#134](https://github.com/grcengineering/how-to-harden/pull/134). Guide version **0.2.0**: **23 controls, 39 source packs across six types**. The original 18 control headings/IDs are preserved; new controls are 1.6 and 4.4–4.7.

**No tenants declared — Tier 0+1 only; VERIFIED-LIVE = 0.** This is documentation, structural and offline implementation verification. It is not a completed live `validate-hth-guide` run, a human review or proof of compliance. Maturity remains exactly `["ai-drafted"]`, with zero live surface marks. No Tailscale/IdP setting, endpoint policy, TPM, node state, DNS configuration or live credential was changed or created.

## Source reconciliation

The [source-first ledger](tailscale-source-coverage.md) records **42 candidates: 37 covered, 4 excluded, 1 unverified**. It begins from feature/client indexes, daemon and system-policy references, then follows the actual configuration bodies, limitations, defaults and recovery. It separately records the six automation surfaces and read/write/lifecycle decisions. There are no unresolved documented guidance gaps inside the declared scope; this does not assert complete product coverage.

The remaining customer-specific MachineCertificateSubject contract is not supplied. The node-state posture example's type conflict, SCIM/user-approval conflict, package-specific defaults and runtime behavior require a suitable vendor/tenant pilot; none is called verified absence. Separate PAM/Aperture and generic infrastructure/application deployment runbooks remain explicitly excluded. Failed fetches and canonical-source fallbacks are distinguished.

## Executed local checks

| Check | Observed result and limit |
|-------|---------------------------|
| `make test-tailscale-packs` | **PASS: 36 existing Python tests and 44 new Bun tests, 315 Bun assertions.** Vendor binaries are local fakes. Cases cover supported native formats/version floors, invalid target/ID/profile rejection, private output/no overwrite, selected state types, missing/malformed/error responses, secret projection, partial collection discard and mutation rejection. |
| Go SDK tests | **PASS: 7 top-level tests**, including malformed/partial inventory, constrained authenticated GET, redirect/error privacy, body bounds, private output and invalid inputs. Actual pinned upstream SDK 2.12.0 and pinned transitive source checkouts were used with a local temporary modfile and `GOPROXY=off`; no replacement path is committed. An initial sandboxed attempt was stopped after stalling; the elevated offline run completed successfully. Normal proxy dependency retrieval is additionally wired into CI. |
| ShellCheck | **PASS**, all Tailscale common, API, CLI and config shell files, including the new shared native-policy helper. |
| `terraform fmt -check -recursive` | **PASS.** Fifteen `command = plan` scenarios use a mocked Tailscale provider. The five new DNS cases cover L2 gating, complete configuration retention, invalid resolver rejection and exit-node version-review acknowledgment. |
| Local Terraform init/schema/plans | **BLOCKED by dependency retrieval**, not reported as passed. Registry discovery timed out after retries; an official release-asset fallback failed with a TLS handshake timeout. An elevated registry attempt also timed out. No provider binary was obtained and no local Terraform validate/test ran. The dedicated CI job downloads the real pinned provider, validates schema and runs all 15 mocked plans without Tailscale credentials. |
| `bash scripts/sync-packs-to-data.sh` | **PASS**, every vendor printed success. Tailscale generated data contains the 39 source packs / 22 covered control keys. Ninety unrelated generated timestamp-only changes were compared to HEAD and restored byte-for-byte; no other vendor content is changed. |
| `bash scripts/validate-guides.sh` | **PASS: ALL TESTS PASSED, 0 warnings.** |
| Parser/metadata checks | **PASS:** 23 full control anatomies; 18 prior headings preserved; all 22 pack includes have generated keys; no same-section/type collision; zero inline fences; canonical profile names; version/date/changelog/VERSIONS agreement; zero live badges. Source-ledger candidate/disposition counts independently checked. |
| Whole-corpus pack validator | **Same baseline: 5 failures, 6 warning groups**, all failing files outside Tailscale. Failures are existing section/type collisions, two unrelated Bash syntax failures, disallowed extensions and an unrelated prose-only Terraform pack. The vendor argument scopes coverage, not corpus checks. Tailscale now has packs for **22/23** controls; 1.1 is upstream IdP MFA with an evidenced manual verdict. No monoculture or missing first-party CLI finding was introduced. |

The source matrix and guide do not equate a settings artifact, a successfully read attribute, a validated candidate, a route counter or a local status snapshot with observed enforcement. Native generators do not install, reload, restart, check TPMs, enroll nodes or perform recovery. Terraform defaults to zero managed resources and zero inventory reads.

## Render verification

Jekyll **4.4.1** built the actual updated docs successfully with disk cache disabled. The local environment lacks two versions in the repository lockfile, so this build used the already available compatible dependency set from the prior rendering workspace; no repository Gemfile/lockfile was modified. CI uses the repository lockfile on its clean runner.

The Interceptor browser skill opened the loopback-only preview in this task's own background tab group. A fresh structured read showed **v0.2.0**, **AI Drafted** and **2026-11-05**. Reading the rendered cheat table returned **23 control rows, all 69 cells nonempty**, including 1.6 and 4.4–4.7. Browser DOM counts returned **39 pack sections** and **zero empty code elements**. The temporary tab group was closed and its absence verified; other browser groups were left untouched. The preview server was loopback-only.

This verifies the locally rendered branch. The public site cannot contain this unmerged change yet, so the skill's post-deploy spot check is **SKIPPED pending maintainer merge/deployment**, not substituted with a claim about the live site.

## Review gates and remaining limits

The blocking `validate-packs.sh --touched` gate requires a committed branch comparison and is run before push; its outcome is included in the PR verification record. The new **Tailscale Terraform Safety** and **Tailscale SDK Safety** jobs run with no product credentials; the PR checks are the authoritative result of those clean-runner executions. This file records local results at authoring time and does not predeclare a pending CI run successful.

No live console paths, state encryption/recovery, MDM installation, policy engine, application connectivity, DNS query path, Taildrive authorization, SIEM ingestion or stream delivery were tested. Required platform/version prerequisites, unsupported/unknown values and independent recovery are documented rather than exercised on the user's devices. Policy fragments need full-policy reconciliation; generated device settings need an existing management owner; the DNS resource owns the complete configuration and requires import/review. Taildrive/Taildrop/declarative sharing lifecycle limits and deprecated SSH recording are retained. A reviewer with an authorized disposable tailnet/fleet must perform applicable runtime tests before deployment.
