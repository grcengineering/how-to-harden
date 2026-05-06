# HTH Anthropic Claude Control 2.3: WIF — Python SDK pattern
# Profile: L2 | NIST: IA-5(1), IA-9, AC-3 | SOC 2: CC6.1
# https://howtoharden.com/guides/anthropic-claude/#23-eliminate-static-api-keys-via-workload-identity-federation
#
# Demonstrates the official `anthropic` Python SDK's Workload Identity
# Federation credentials. The SDK exchanges the IdP JWT for a short-lived
# Anthropic access token and refreshes it automatically before expiry
# (botocore-style two-tier refresh: advisory at exp-120s, mandatory at exp-30s).
# Reference: https://platform.claude.com/docs/en/manage-claude/workload-identity-federation

# HTH Guide Excerpt: begin sdk-wif-python-explicit
from anthropic import Anthropic, WorkloadIdentityCredentials, IdentityTokenFile

# Explicit construction — recommended when you ship one image to multiple
# environments and want the federation parameters in code rather than env.
client = Anthropic(
    credentials=WorkloadIdentityCredentials(
        identity_token_provider=IdentityTokenFile(
            "/var/run/secrets/anthropic.com/token"
        ),
        federation_rule_id="fdrl_REPLACE_ME",
        organization_id="00000000-0000-0000-0000-000000000000",
        service_account_id="svac_REPLACE_ME",
        workspace_id="wrkspc_REPLACE_ME",
    ),
)

message = client.messages.create(
    model="claude-sonnet-4-6",
    max_tokens=1024,
    messages=[{"role": "user", "content": "Hello, Claude"}],
)
print(message.content[0].text)
# HTH Guide Excerpt: end sdk-wif-python-explicit

# HTH Guide Excerpt: begin sdk-wif-python-env
# Zero-argument construction — recommended for production. Ship the same
# container image everywhere; inject these env vars per environment:
#   ANTHROPIC_FEDERATION_RULE_ID
#   ANTHROPIC_ORGANIZATION_ID
#   ANTHROPIC_SERVICE_ACCOUNT_ID
#   ANTHROPIC_WORKSPACE_ID         (required when the rule covers >1 workspace)
#   ANTHROPIC_IDENTITY_TOKEN_FILE  (or ANTHROPIC_IDENTITY_TOKEN literal)
#
# IMPORTANT: ANTHROPIC_API_KEY sits ABOVE federation in the SDK's credential
# precedence chain. A leftover key silently shadows federation. The next block
# is a defensive startup check.
import os, sys

for var in ("ANTHROPIC_API_KEY", "ANTHROPIC_AUTH_TOKEN"):
    if os.environ.get(var):
        sys.exit(
            f"FATAL: {var} is set; it will shadow Workload Identity Federation. "
            "Unset it (empty-string also wins precedence)."
        )

from anthropic import Anthropic
client = Anthropic()  # SDK reads the ANTHROPIC_FEDERATION_* vars from env
# HTH Guide Excerpt: end sdk-wif-python-env
