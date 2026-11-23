#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: inspect-2.2
#   guide: https://howtoharden.com/guides/inspect/#22-review-custom-agent-access
#   profile: L1
#   mode: read-only
#   requires: bash, curl, jq, python3, INSPECT_API_KEY with target access
# HTH 2.2: Review Custom Agent Access
# Profile: L1 | NIST SP 800-53 AC-6 | https://howtoharden.com/guides/inspect/
# Sources: https://docs.inspect.com/api/openapi.json (2026-11-17; available v2 routes).
# No live tenant validation. Download common.sh beside this file.
# HTH Guide Excerpt: begin audit-agent
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/common.sh"
hth_init
id=${INSPECT_AGENT_ID:-}; hth_id "$id"
hth_request GET "/api/v2/agents/$id" "$HTH_TEMP/agent.json"
hth_agent_valid "$id" "$HTH_TEMP/agent.json"
# Never emit prompts, skills contents, or arbitrary tool configuration.
jq '{scope:"One exact agent, not an organization-wide inventory",warning:"Deprecated capabilities are NOT a security boundary; git_write false does not block pushes or pull requests",agent:(.data|{id,name,builtin,repositories,skills,prompt_context_mode}),unrestricted_repositories:(.data.repositories==null)}' "$HTH_TEMP/agent.json" > "$HTH_TEMP/output.json"
hth_save "$HTH_TEMP/output.json"
printf 'COLLECTED: agent repository and skill configuration. Review connected systems separately.\n'
# HTH Guide Excerpt: end audit-agent
