#!/usr/bin/env bash
# HTH Anthropic Claude Control 7.9: Deploy External Sandbox Tooling
# Profile: L3 | NIST: SC-39, SC-7 | SOC 2: CC6.1, CC6.8
# https://howtoharden.com/guides/anthropic-claude/#79-deploy-external-sandbox-tooling
#
# Setup and usage scripts for kernel-enforced sandbox tools that wrap
# Claude Code in an isolation layer independent of Claude's own sandbox.
# Tools: nono (Apache-2.0), NVIDIA OpenShell (Apache-2.0)
#
# These tools provide defense-in-depth: even if Claude Code's built-in
# sandbox is bypassed, the kernel-level restrictions remain enforced.
#
# Usage: ./hth-anthropic-claude-7.09-external-sandbox.sh [--install]
#   --install  also install nono and OpenShell (skipped by default)
#   NONO_SESSION_ID  a session id from `nono audit list`, for the audit step

set -euo pipefail

# HTH Guide Excerpt: begin nono-setup
# ── nono: Kernel-Enforced Agent Sandbox ──
# Source: github.com/nolabs-ai/nono (Apache-2.0)
# Platforms: macOS (Seatbelt), Linux (Landlock)
# Docs: docs.nono.sh

# Install nono via Homebrew (only when run with --install)
if [[ "${1:-}" == "--install" ]]; then
  brew install nono
fi

# Run Claude Code inside nono with the built-in profile.
# The claude-code profile grants:
#   - Read/write to CWD only
#   - Network access via allowlisted proxy
#   - Credential injection without disk exposure
#   - Filesystem snapshots for atomic rollback
nono run --profile claude-code -- claude

# Custom hardened invocation:
#   --rollback        Enable filesystem snapshot/restore
#   --proxy-credential Inject API key via HTTPS proxy (never touches disk)
#   --supervised      Require interactive approval for flagged operations
nono run \
  --profile claude-code \
  --rollback \
  --proxy-credential anthropic-api-key \
  --supervised \
  -- claude

# Audit trail: review all actions taken during a session
nono audit list
nono audit show "${NONO_SESSION_ID:?set NONO_SESSION_ID to a session id from 'nono audit list'}" --json

# Rollback: restore filesystem to pre-session state
nono rollback list
nono rollback restore
# HTH Guide Excerpt: end nono-setup

# HTH Guide Excerpt: begin openshell-setup
# ── NVIDIA OpenShell: Container-Based Agent Sandbox ──
# Source: github.com/NVIDIA/OpenShell (Apache-2.0)
# Platforms: Linux (container-based via K3s)
# Docs: github.com/NVIDIA/OpenShell/tree/main/docs

# Install OpenShell (only when run with --install).
#
# NOT a download piped straight into a shell. That runs whatever the endpoint
# serves at that instant, unreviewed and unverifiable — the delivery path behind
# the Codecov bash-uploader and Polyfill.io compromises. A hardening guide must
# not teach it. Fetch to a file, pin the revision, verify the bytes, then run it.
#
# Pinned to the v0.1.2 release tag (commit 6648bd0c290efbc41ba131ee9831ee45cd431f94)
# and the sha256 of that tag's install.sh, verified by downloading it directly on
# 2026-10-05. Bump both together when you deliberately move to a newer release —
# never relax the check.
OPENSHELL_REF="${OPENSHELL_REF:-v0.1.2}"
OPENSHELL_SHA256="${OPENSHELL_SHA256:-5c98a86a4b811c471b212219cb2a62d458244220ffa71ac8e3baf3700b17b871}"

if [[ "${1:-}" == "--install" ]]; then
  OPENSHELL_INSTALLER="$(mktemp)"
  curl -fsSLo "${OPENSHELL_INSTALLER}" \
    "https://raw.githubusercontent.com/NVIDIA/OpenShell/${OPENSHELL_REF}/install.sh"

  echo "${OPENSHELL_SHA256}  ${OPENSHELL_INSTALLER}" | sha256sum -c - \
    || { echo "OpenShell installer digest mismatch — refusing to run" >&2; exit 1; }

  # Read it before you run it; then run the bytes you just verified.
  sh "${OPENSHELL_INSTALLER}"
  rm -f "${OPENSHELL_INSTALLER}"
fi

# Launch Claude Code in an isolated sandbox.
# OpenShell auto-detects ANTHROPIC_API_KEY, creates a provider,
# and injects credentials without persisting them to disk.
openshell sandbox create -- claude

# Apply a custom security policy (YAML-based).
# Static policies (filesystem, process) are locked at creation.
# Dynamic policies (network, inference) can be hot-reloaded.
openshell policy set hardened-claude --policy ./claude-policy.yaml

# Monitor sandbox activity in real time
openshell term

# View sandbox logs
openshell logs --tail

# List and manage running sandboxes
openshell sandbox list
openshell sandbox connect "${SANDBOX_NAME:?set SANDBOX_NAME to a name from the list above}"
# HTH Guide Excerpt: end openshell-setup
