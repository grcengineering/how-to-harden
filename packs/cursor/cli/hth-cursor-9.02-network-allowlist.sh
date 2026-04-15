#!/usr/bin/env bash
# HTH Cursor Control 9.2: Configure Network Allowlisting
# Profile: L3 | NIST: SC-7
# https://howtoharden.com/guides/cursor/#92-configure-network-allowlisting

# HTH Guide Excerpt: begin cli-network-verification
# Monitor Cursor network connections and verify only approved endpoints
echo "=== Active Cursor Network Connections ==="
if [[ "$OSTYPE" == "darwin"* ]]; then
  lsof -i -n -P 2>/dev/null | grep -i cursor | grep ESTABLISHED
elif [[ "$OSTYPE" == "linux"* ]]; then
  ss -tnp 2>/dev/null | grep cursor
fi

echo ""
echo "=== Verify against approved endpoints ==="
echo "Required domains (allowlist these in firewall):"
echo "  *.cursor.com          — Core application services"
echo "  *.cursor.sh           — Authentication and SSO"
echo "  *.cursorapi.com       — API services and marketplace"
echo "  cursor-cdn.com        — CDN for static assets"
echo "  downloads.cursor.com  — Client downloads and updates"
echo ""
echo "Optional (only if using cloud AI providers):"
echo "  api.openai.com        — OpenAI API (routed through Cursor proxy)"
echo "  api.anthropic.com     — Anthropic API (routed through Cursor proxy)"
echo ""
echo "Block all other outbound connections from Cursor."
# HTH Guide Excerpt: end cli-network-verification
