# Native schema fixtures

Public, first-party schemas retrieved 2026-11-15/16; retained for offline regression testing, not fetched during tests. Upstream projects are MIT licensed; retain the [license notices](LICENSES.md). No secrets or tenant data.

| Fixture | Source | SHA-256 |
|---|---|---|
| `opencode.schema.json` | https://opencode.ai/config.json | `b0e0a39a0a7cc3e91763bbc73092b2b7dba99b4810bf90750e6df5b077cfa8e7` |
| `pi.schema.json` | https://pi.dev/schemas/settings.schema.json | `10c0b73ace40dd0a3461a45f08cb819b39b1089ce7037e27b746fc812f28beb9` |
| `models.schema.json` | https://models.dev/model-schema.json | `fc1d371a407080cfd19511ea53155abf4a5f73951ed555c4c681074e32861a51` |

The tests resolve in-document references plus the explicitly cached models.dev dependency; no remote retrieval occurs. A passing schema check establishes shape against this snapshot, not runtime behavior, precedence or semantic enforcement. Hermes and OhMyPi candidates are checked against release documentation and typed baseline fixtures; no independent vendor JSON Schema is claimed.
