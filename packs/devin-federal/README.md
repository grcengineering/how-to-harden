# Devin Federal Code Pack

Companion to the [Federal guide](https://howtoharden.com/guides/devin-federal/); [source-first ledger](https://howtoharden.com/research/cognition-source-coverage-2026-11/). Federal portal and air-gapped beta host files are separate from commercial Devin. Public source bodies were fetched 2026-11-05.

| Control | Surfaces | Behavior |
|---------|----------|----------|
| 1.2 | API; actual SDK CLI wrapper | JSON POST ListGroups/GetGroup are reads, scoped to the key. Full pagination; private no-overwrite policy evidence. SDK wrapper lists groups only. |
| 2.1 | native config emitter | HTTPS public-client OIDC policy with required group; no login or deployment |
| 2.2 | first-party air-gapped CLI | Version/model validation; explicit --probe adds auth refresh and doctor endpoint probes |
| 3.1 | native config emitter | Approved HTTPS model and environment key NAME, no secret content or deployment |
| 4.2 | native Filebeat config; Splunk SPL | Namespace/rotation-aware ingestion fragment and schema-1 authentication action investigation query |

## Safe operation

API needs Bash/curl/jq/Bun, existing WINDSURF_SERVICE_KEY, HTH_PROFILE_LEVEL=2, confirmed DEVIN_FEDERAL_API_URL HTTPS origin and a new HTH_OUTPUT_FILE in a trusted directory. Download api/common.sh with the script. The key enters the JSON body from environment and never argv; all requests are allowlisted reads, ignore .curlrc, refuse redirects and bound transport/pages. Empty visible groups is not team-wide or secure evidence. The group detail schema includes model lists and optional configured/effective cap; manual user overrides and team bounds still require reconciliation.

For the CLI SDK wrapper supply the actual trusted DEVIN_FEDERAL_SDK path downloaded from portal Analytics → Download SDK, the same key/origin, Python3/requests and trusted HTH_EVIDENCE_DIR. The real SDK is access-gated and was not downloaded/tested. Wrapper tests verify dispatch and private output only; no fake SDK is shipped.

SDK collection and both policy emitters require HTH_PROFILE_LEVEL=2 (or 3/4) before work. OIDC emitter requires DEVIN_OIDC_ISSUER, DEVIN_OIDC_CLIENT_ID and DEVIN_OIDC_REQUIRED_GROUP. It emits strict schema-version-0 auth.json with no client secret or extra endpoint hosts. Host files/parents and actual launch environment must be protected by endpoint management; missing auth.json means license-only. DEVIN_AUTH_FILE and DEVIN_MODELS_FILE can select different files; protected defaults alone do not establish immutable policy.

Model emitter requires DEVIN_MODEL_NAME, DEVIN_MODEL_BASE_URL, DEVIN_MODEL_KEY_ENV and positive DEVIN_MODEL_CONTEXT; optional DEVIN_MODEL_API is chat_completions or responses. It never reads the credential variable’s value. It follows the newer November 3 release’s query/fragment rejection despite conflicting model-reference prose. Validate with the installed supported build and deliver the secret into the actual Desktop/CLI process environment.

Health inventory defaults to version and models validate; --probe explicitly adds auth status and airgap doctor (which can contact IdP/model endpoints). It neither starts an agent nor installs a license. Store/review diagnostic output privately. A command success is not proof every warning or host ACL is secure.

Merge Filebeat input with actual OS/XDG paths and protected TLS output/retention; preserve owner-only logs and authorized collector access. Its timestamp processor is beta. The 64-byte fingerprint setting matters for small files and changing it can replay data. Run the marked SPL query only, excluding repository metadata comments; use actual source/index configuration. Auth is event=auth with action fields. File-read/write events represent permission scope, not verified I/O. No Splunk/Filebeat runtime was available.

Exit 0 means a particular inventory/emission completed, not global compliance; exit 2 is unknown/input/transport/incomplete evidence. Offline tests: bun test --timeout 30000 scripts/test-cognition-refresh.test.ts. No live federal portal, IdP, inference service, CLI installation, SDK, collector or license was used.
