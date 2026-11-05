# Cursor Cloud Agents packs

Download this complete folder. The numbered API Bash wrapper needs Bun and the adjacent `inventory-agents.ts` and `common.ts` helpers. It is a native REST client, not a vendor SDK. Run it with `bash api/hth-cursor-cloud-agents-5.02-inventory-agents.sh` and an existing `CURSOR_API_KEY`.

The GET inventory paginates active and archived durable agents belonging to the authenticated user. It does not establish a team inventory or worker, environment, snapshot, secret or retention posture. JSON `status: REVIEW` and exit 0 mean the read completed and needs operator review. JSON `status: UNKNOWN` and exit 3 mean a missing precondition, transport failure or response-schema mismatch; missing Bun exits 2. Names, prompts, repository URLs and raw API bodies are suppressed. No agent is launched, steered, archived or deleted.

The Terraform folder pins the first-party `cursor/cursor` provider to `0.8.0`. Read `variables.tf` and the complete control file together. A by-ID workflow data-source read is optional and requires an actual reviewed automation ID. Resource creation/management and enablement are separate opt-ins, both false by default. The example stays private, uses the creator's scope, restricts the Slack trigger to one reviewed channel and a prefix, disables PR creation, and enables no predefined actions or memory. A prompt does not constrain the runtime's other credential/tool authority.

Terraform state may contain the workflow prompt and identity metadata; protect state and plan output. No credentials are included. Configure existing provider authentication according to the pinned provider documentation, inventory/import existing resources where appropriate, and review a plan before applying. This refresh ran provider initialization and schema validation without vendor credentials; it did not configure a tenant, install a Slack integration, plan or apply resources.

See [the guide](../../docs/_guides/cursor-cloud-agents.md) for execution, network, identity, trigger and containment boundaries.
