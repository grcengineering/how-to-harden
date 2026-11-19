# Assembled Code Packs

Download the complete `packs/assembled`, `packs/assembled-wfm` and `packs/assembled-ai` directories. API wrappers share `packs/assembled/api/common.py`; the generated guide excerpts depend on that file and are not standalone copies.

The administrative packs make GET requests only. Inject `ASSEMBLED_API_KEY` using your secret manager, such as a configured 1Password Environment. Assembled documents Basic authentication with the key as username and an empty password; it does not document a restricted read-only key scope. A read-only script does not reduce its credential's underlying privileges. The code pins the HTTPS API origin, does not follow redirects, disables curlrc/proxies, keeps credentials off argv, and fails without a report on incomplete or inconsistent pagination. No production credential is needed for the offline tests.

| Pack | Invocation / output | Limit |
|------|---------------------|-------|
| Shared roles | `bash packs/assembled/api/hth-assembled-1.02-audit-role-membership.sh` | Role membership counts; inspect effective permissions in the console |
| Departed people | `bash packs/assembled/api/hth-assembled-1.03-reconcile-departed-people.sh /private/departed-addresses.txt` | Private input has one departed email per line. Output contains matching person IDs and soft-delete state, not login/deactivation state |
| Schedule changes | Set `ASSEMBLED_START_TIME` and `ASSEMBLED_END_TIME` as Unix seconds, then run `bash packs/assembled-wfm/api/hth-assembled-wfm-3.01-collect-schedule-changes.sh` | At most 31 days per run; NDJSON contains actor IDs and must be retained privately |
| Splunk detection | Ingest schedule NDJSON under `assembled:event_changes`, extract event time from `modified_at`, then paste the marked SPL query (omit the repository metadata header) | Custom ingestion convention, no official Splunk integration; tune the 25-event threshold and review legitimate bulk operations |
| Browser session reset | Import the module under `packs/assembled-ai/sdk/` and await `clearAssembledChatSession()` from the application's serialized logout/account-switch flow | Changes live widget session; requires official browser SDK and a working session-clear CSP/network path |

Use a private temporary output file and atomically promote it only after a collector exits 0. Directory inventories intentionally emit `REVIEW`; they are not compliance scores. Schedule output can be empty after a successful collection. Keep overlapping windows and deduplicate event IDs downstream. A changed total, repeated record or malformed response fails rather than silently accepting partial evidence.

The widget function never initializes another session automatically. Its vendor teardown call can resolve after two seconds even if clearing fails; test the actual network request and two-user isolation before production integration. Never place the JWT signing secret in browser code.

Run `python3 scripts/test-assembled-packs.py` for transport/pagination, privacy and mocked browser-lifecycle tests. These fixtures are not live Assembled, browser, or Splunk validation. See [the evidence ledger](../../docs/research/assembled-source-coverage.md).
