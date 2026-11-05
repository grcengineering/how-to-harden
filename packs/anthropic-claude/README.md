# Anthropic common, Code and API packs

Historical pack section keys are retained for existing guide includes. Header URLs point to the actual Common Controls, Claude Code or API control. Enterprise-specific additions live in [claude-enterprise](../claude-enterprise/README.md).

The API helper fixes the HTTPS host to `api.anthropic.com`, disables curlrc/redirects, passes credentials through stdin, uses bounded requests and rejects incomplete pagination. Direct API examples do not transparently support Claude Platform on AWS, Government or other provider endpoints. API version is 2026-10-21; beta headers are declared by the relevant pack. An inventory result is not evidence that SSO, retention, residency or least privilege is enforced.

Mutations require `HTH_APPLY=1` in addition to the pack's explicit target variables. Workload identity exchange separately requires `HTH_EXCHANGE=1`; its default neither exchanges a token nor makes a billable inference call. The Python SDK example constructs the current official client after credential-precedence checks; it does not send an inference request.

The new workspace CLI uses official `ant` through the Enterprise helper. Workspace Terraform pins the **community** `jianyuan/anthropic` provider at 0.3.0. The default empty set plans no resources; mock tests do not contact Anthropic. Review credential/state storage, irreversible workspace archive and immutable storage geography before any real use. `prevent_destroy` is not a recovery plan and does not protect unmanaged API changes.

Each JSONC excerpt is a separate native fragment; do not concatenate entire files into one JSON request. Managed Agents examples contain **separate Agent and Environment request bodies**. Code system files, server policy, Desktop MDM and organization capability settings are different planes. Local-file checkers cannot prove effective server/MDM enforcement. The optional remote-refresh fragment can block startup and requires a tested recovery path. Container examples require independent image, host, mount and network review; they do not install external wrappers or prove isolation.

The CI example is manually dispatched against a reviewed commit and requires a protected environment configured separately. It uses a read-only GitHub token and log-only output; it neither installs a GitHub App nor automatically runs privileged analysis on arbitrary PR content. The rules scanner is heuristic, not a proof of injection absence.

Run the offline regression suite with `bun test scripts/test-anthropic-refresh.test.ts` after installing the locked Enterprise SDK. No live tenant, paid inference, MDM, identity migration, destructive recovery or Government runtime was exercised. See the [source reconciliation](../../docs/research/anthropic-source-coverage-2026-11.md).
