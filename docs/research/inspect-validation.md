# Inspect validation record

Date: 2026-11-17. Scope: new Inspect guide and packs; Ramp guide editorial cross-link only. **No tenants declared — Tier 0+1 only.** No Inspect API key, live tenant, credential injection environment or live configuration change was used. Documentation-derived paths do not establish live effectiveness.

## Scope and method

- Read the repository authoring, verification, validation and source-discovery playbooks.
- Read the current public Inspect full-document export and linked OpenAPI; reconcile administrative areas and available read/write surfaces before selecting controls. See [source coverage](inspect-source-coverage.md).
- Isolated branch from main; existing unrelated local work preserved. New guide remains `ai-drafted` with no validation marks.
- API fixtures use a fake curl process and synthetic identifiers. Config tests generate local candidates without installing policies or invoking cloud roles.
- Independent code/content review identified and corrected a mutable-allowlist input race, native review filename mismatch and documentation/pack anchor/profile mismatches. A frozen validated input now supplies both the non-broadening check and PATCH body. Added regression tests and reran the same suite.

## Results

| Check | Result | Boundary |
|-------|--------|----------|
| API transport and operation safety | PASS: 39 offline tests | Redirect/origin/header rejection; pagination limits/missing/repeated cursors/duplicates; private evidence; no retries; exact apply gates; non-broadening writes; input rewrite/concurrency/read-back regressions; verification target/status guards. |
| Config emitters | PASS: 12 offline tests | Exact OIDC issuer/audience/subject and lifecycle; local skill paths and traversal constraints; no network or deployment. |
| Approval baseline | PASS: 3 offline tests | Native keys and explicit deny-only default/path rules. Not Inspect's policy evaluator. |
| Shell syntax and ShellCheck | PASS | Shared helper, six API scripts and two config emitters. |
| Guide anatomy | PASS | 20 Inspect controls and 23 existing Ramp controls have full parser anatomy; zero fenced guide blocks. |
| Guide lint | PASS | `validate-guides.sh` ends ALL TESTS PASSED, zero warnings. |
| Generated excerpts | PASS | Sync completed with no vendor errors; nine Inspect pack files map to eight sections (4.2 has both API and config). Timestamp-only changes to unrelated generated data excluded. |
| Jekyll build and rendered browser | PASS | Build completed using repository lockfile and isolated dependency directory. Isolated headless browser rendered 20 control rows plus two level headers, no empty cells, nine pack blocks and no empty code blocks. |
| API/ClickOps/policy behavior | SKIPPED: no tenant or credentials declared | No live requests, IAM changes, policy deployment, agent work or spend. Documentation checks only. |
| OCEAN | SKIPPED: installed binary lacks required build capability | Repository exists, no repo-local release/debug binary; PATH `ocean build --help` reports unrecognized subcommand. No Inspect scanner module authored; scanner conformance/live scan not claimed. |
| Public deployment | SKIPPED: review PR, not merged/deployed | A local build is not a live howtoharden.com publication. |

**54 offline tests passed.** No `VERIFIED-LIVE` results exist. The guide deliberately retains only `ai-drafted`.

## Repository debt outside this change

Whole-corpus pack validation reports five existing failure groups outside Inspect:

- Two existing section/type collisions (Bitbucket 4.3 and HashiCorp Vault 5.2).
- HashiCorp Vault 1.1 shell syntax failure.
- DockerHub 2.4 shell syntax failure.
- Eleven existing extension/type violations in HashiCorp Vault, Tableau, Wiz and Azure DevOps.
- One comments-only Azure DevOps Terraform file.

These were not fixed, excluded or downgraded. The initial pre-sync run also reported missing generated Inspect YAML; sync resolves that new-artifact finding. Repository coverage warnings are not a claim of Inspect coverage failure: Inspect has API plus native config packs; remaining controls carry explicit documented limitations.

## Operational caveats

- Mutating API packs preview by default; running them requires separate authorized exact-target approval and the explicit apply variables. They retain sensitive evidence privately and never roll back automatically.
- No conditional-write/expected-SHA primitive is documented. Rechecks narrow but do not eliminate races; inspect current state after an uncertain response.
- Verification API acceptance is not successful verification, a human approval or a completed test. It can start paid work, supersede prior runs and bypass automatic-verification opt-out.
- Gated Trust Center materials, complete interactive catalog and deployment-specific settings remain unverified. No credentials, NDA or access request was used to fill those gaps.
