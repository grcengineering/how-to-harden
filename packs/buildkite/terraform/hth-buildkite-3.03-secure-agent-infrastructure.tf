# =============================================================================
# HTH Buildkite Control 3.3: Secure Agent Infrastructure
# Profile Level: L2 (Hardened)
# Frameworks: CIS 4.1 | NIST CM-6
# Source: https://howtoharden.com/guides/buildkite/#33-secure-agent-infrastructure
#
# NOTE: Agent host infrastructure hardening is performed outside Buildkite
# and cannot be managed by the Buildkite Terraform provider. This control
# covers OS-level hardening, network restrictions, and ephemeral agent
# configuration on the hosts where buildkite-agent runs.
#
# This file documents the control requirement and references
# infrastructure-as-code patterns for agent host security.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Agent infrastructure hardening is managed outside the Buildkite provider.
# This control requires:
#   1. Use ephemeral agents (containers or auto-scaling instances)
#   2. Minimize installed software on agent hosts
#   3. Apply OS hardening (CIS benchmarks for the host OS)
#   4. Restrict agent network access to required endpoints only
#   5. Use private networks for agent-to-service communication
#   6. Monitor agent traffic for anomalies
#
# Recommended infrastructure patterns:
#   - AWS: buildkite/elastic-ci-stack-for-aws (CloudFormation/Terraform)
#   - GCP: buildkite/elastic-ci-stack-for-gcp
#   - Kubernetes: buildkite/agent-stack-k8s
#
# Agent configuration flags for hardening:
#   --no-plugins          Disable third-party plugins
#   --no-local-hooks      Disable repository-level hooks
#   --no-command-eval      Disable arbitrary command evaluation
#   --allowed-repositories Restrict which repos agents can checkout
#
# Example agent startup with hardened flags (L3):
# buildkite-agent start \
#   --no-plugins \
#   --no-local-hooks \
#   --no-command-eval \
#   --allowed-repositories "git@github.com:your-org/*"
# HTH Guide Excerpt: end terraform
