# =============================================================================
# HTH Azure DevOps Control 3.3: Self-Hosted Agent Installation
# Profile: L1 | NIST: SC-7
# =============================================================================

# HTH Guide Excerpt: begin cli-install-agent
# Agent installation with security
# Run as service account (not admin)
# Limit network access
# Enable audit logging

.\config.cmd --unattended `
    --url https://dev.azure.com/your-org `
    --auth PAT `
    --token $env:AGENT_PAT `
    --pool "Production-Agents" `
    --agent $env:COMPUTERNAME `
    --runAsService `
    --windowsLogonAccount "DOMAIN\svc-agent"
# HTH Guide Excerpt: end cli-install-agent
