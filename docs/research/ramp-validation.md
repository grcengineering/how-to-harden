# Ramp validation record

Date: 2026-11-08. Scope: new commercial Ramp guide and Code Packs. Maturity remains `ai-drafted`. No customer tenant, tokens, identity provider, browser management domain, or SIEM was supplied. No payment or live control change was performed.

## Evidence review

The [source-first coverage ledger](ramp-source-coverage.md) records current first-party support/configuration content, the 189-path REST/OpenAPI snapshot, official CLI source, Alpha SDK, public Trust modal guidance, and the rendered 19-document catalog. Seventeen private documents remain unread. No claim of exhaustive private-document coverage is made.

Independent semantic review identified and resolved three issues before publication: explicitly authorize the requesting user for the card ID before minting embed access; distinguish Linux Chrome policy JSON from Google Admin configuration; and review failed ERP authentication in the provider UI rather than a field omitted by the metadata pack. Suspended-user coverage and the audit projection are explicit. Alpha agent/SDK capabilities and wallet-policy semantic gaps are recorded separately from the stable REST surface.

## Local checks

| Check | Result | Boundary |
|---|---|---|
| `python3 scripts/test-ramp-packs.py` | PASS, 17 tests | Mocked curl/CLI only; no live endpoint, credential, install or deployment. |
| `bash scripts/validate-guides.sh` | PASS, all tests, zero warnings | 151-guide structural lint; not correctness of live UI paths. |
| Zero inline fences; parser-exact Description/Rationale/Profile anatomy | PASS, 23 controls | Source parser checks, not rendered live site. |
| `bash scripts/sync-packs-to-data.sh` | PASS; 9 Ramp sections | All 9 includes resolve; unrelated generated timestamp-only changes discarded. |
| Metadata, changelog, generated registry and doc links | PASS | 0.1.0, 2026-11-08, ai-drafted only. No status badges. |
| `bash scripts/validate-packs.sh ramp` | Ramp has no attributed failures; whole-corpus exit 1 | Vendor argument scopes coverage, not all checks. Existing other-vendor debt remains: two collisions, two shell syntax failures, eleven extension/type violations, one prose-only pack. Five failed check reports overall. |
| `bash scripts/validate-packs.sh --touched` | PASS, exit 0 | No failures in the files this branch touched; unrelated corpus debt remains visible. |
| Commit diff whitespace | PASS except generated-file convention | The pack sync emits a terminal blank line in ramp.yml; retained to satisfy exact freshness checks. No other added whitespace errors. |
| Local Jekyll build | BLOCKED before build | The publication Mac has Ruby 3.2.11 and Bundler 2.5.23, but the pinned json 2.19.9 and concurrent-ruby 1.3.7 gems are absent. The draft PR CI is the rendering gate; no local build success is claimed. |

Offline cases include allowed request shapes and fields, explicit suspended users, pagination, query preservation, origin/path/cursor rejection, header injection, HTTP/transport/schema failure, repeated pagination and bounds, invalid audit windows, no partial report emission, no token/error-body leakage, exact CLI flags/rationale without login, and native Chrome policy conversion/schema. All 28 Sigma event strings were checked against the retrieved official OpenAPI enum. The schema subset tests fields consumed by reports, not the entire API.

## Surface validation status

| Surface | Status | What remains |
|---|---|---|
| ClickOps controls 1.1–5.3 | SKIPPED-LIVE | Needs authorized tenant, relevant plan/region/feature flags, controlled users and recovery approvals. |
| API: 1.3, 1.4, 2.3, 2.5, 3.1, 5.1 | OFFLINE-PASS / SKIPPED-LIVE | Needs existing appropriately scoped token; no grants created. Read inventories do not enforce policies. |
| CLI: 2.2 | OFFLINE-PASS / SKIPPED-LIVE | Needs approved installed official CLI and existing session; auth status is manually reviewed. |
| Config: 2.6 | OFFLINE-PASS / SKIPPED-LIVE | Needs Linux Chrome policy merge, privacy approval, pilot, effective-policy check and rollback verification. |
| Sigma: 5.2 | SCHEMA-REVIEWED / SKIPPED-LIVE | Needs backend translation, ingestion mapping, benign positive/negative events and actual delivery test. |
| OCEAN scanner | NOT RUN | No scanner control definitions or live credentialed assessment supplied. No scanner pass/fail posture is claimed. |
| Post-deploy cheat sheet | NOT RUN | This is a draft PR, not a merged publication. Review and merge belong to the maintainer. |

These results earn no `ai-validated`, `ai-reviewed`, or human-review status. Guide coverage is 23 authored controls with 9 substantive packs across API, CLI, config and Sigma; it is not a completeness score for the product. Review the gated-document and experimental-surface gaps before using the material as an organizational baseline.

## Publication status

Prepared as a draft pull request for maintainer review, not a merge or deployment. The prepared patch was transferred with a verified SHA-256 digest and replayed on current main in an isolated worktree. All 17 mocked tests and guide lint passed again during publication. The authoring run's touched-pack gate passed; the Mac's full-corpus rerun was interrupted after filesystem errors and is deferred to the exact-commit CI check. No tenant, payment, or live control change was performed. Post-deploy checks remain pending until a maintainer merges and deploys the guide.
