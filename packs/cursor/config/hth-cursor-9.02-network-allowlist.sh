#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: cursor-9.2
#   guide:   https://howtoharden.com/guides/cursor/#92-configure-network-allowlisting
#   profile: L3
#   mode:    read-only
#   requires: lsof (macOS) or ss (Linux)
# =============================================================================
# HTH Cursor Control 9.2: Configure Network Allowlisting
# Profile Level: L3 (Run) | NIST 800-53: SC-7
# Source: https://howtoharden.com/guides/cursor/#92-configure-network-allowlisting
#
# The allowlist printed below is Cursor's documented list
# (https://cursor.com/docs/enterprise/network-configuration — "IP allowlisting"
# and "SSL inspection"). `*.cursor.com` is NOT on it, and direct provider APIs
# (api.openai.com, api.anthropic.com) should be BLOCKED so model traffic goes
# through Cursor's backend, where Privacy Mode applies. If developers bring
# their own provider keys, those requests are governed by the provider's policy,
# not Cursor's zero-data-retention terms (same page, "LLM gateways").
#
# The connection listing is a snapshot: it shows peer IPs, not hostnames, and
# only while Cursor is running. Resolve and compare against your firewall log.
# =============================================================================

# HTH Guide Excerpt: begin cli-network-verification
# Snapshot Cursor's established connections (peer IPs) to compare with your firewall log
echo "=== Active Cursor Network Connections ==="
if [[ "$OSTYPE" == "darwin"* ]]; then
  lsof -i -n -P 2>/dev/null | grep -i cursor | grep ESTABLISHED || echo "  (no established Cursor connections — is Cursor running?)"
elif [[ "$OSTYPE" == "linux"* ]]; then
  ss -tnp 2>/dev/null | grep -i cursor || echo "  (no established Cursor connections — is Cursor running?)"
fi

echo ""
echo "=== Cursor-documented egress allowlist ==="
echo "Wildcards (Cursor's recommended form):"
echo "  *.cursor.sh           — backend services, API, authentication"
echo "  *.cursor-cdn.com      — static assets, downloads"
echo "  *.cursorapi.com       — extension marketplace (marketplace.cursorapi.com)"
echo "  *.cursorvm.com        — Cloud Agent / Grok Bot VMs (only if used)"
echo "  *.*.cursorvm.com      — nested Cloud Agent / Grok Bot hostnames (only if used)"
echo "Also required for client updates and extension downloads:"
echo "  downloads.cursor.com"
echo "  anysphere-binaries.s3.us-east-1.amazonaws.com"
echo ""
echo "BLOCK direct provider APIs so model traffic goes through Cursor's backend (Privacy Mode):"
echo "  api.openai.com"
echo "  api.anthropic.com"
echo ""
echo "Block all other outbound connections from Cursor."
# HTH Guide Excerpt: end cli-network-verification
