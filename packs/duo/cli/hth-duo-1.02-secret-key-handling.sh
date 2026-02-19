#!/usr/bin/env bash
# =============================================================================
# HTH Duo Control 1.2: Secret Key Handling Best Practices
# Profile: L1
# =============================================================================

# HTH Guide Excerpt: begin cli-secret-key-handling
# Bad: Hardcoded in script
SKEY="your-secret-key"

# Good: Environment variable
SKEY=$DUO_SECRET_KEY

# Better: Secrets manager
SKEY=$(vault kv get -field=skey secret/duo/application)
# HTH Guide Excerpt: end cli-secret-key-handling
