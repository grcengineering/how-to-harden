#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: tailscale-4.7
#   guide: https://howtoharden.com/guides/tailscale/#47-govern-dns-resolvers-and-certificate-name-disclosure
#   profile: L2
#   mode: read-only
#   requires: TAILSCALE_ACCESS_TOKEN(dns:read), TAILSCALE_TAILNET, TAILSCALE_OUTPUT, bash, curl, jq, python3
# HTH Tailscale 4.7 — Govern DNS Resolvers and Certificate Name Disclosure; NIST SC-20, SC-21; SOC 2 CC6.6
# Sources: https://tailscale.com/docs/reference/trust-credentials
# https://github.com/tailscale/tailscale-client-go-v2/blob/v2.12.0/dns.go (available; 2026-11-05)
set +x
set -Eeuo pipefail
# shellcheck source=common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

# HTH Guide Excerpt: begin review-dns-configuration
hth_api_init 2
for setting in nameservers preferences searchpaths split-dns; do
  hth_get "/api/v2/tailnet/${HTH_TAILNET}/dns/${setting}" "$HTH_TEMP/$setting"
done
jq -e '.dns | type == "array" and all(.[]; type == "string")' "$HTH_TEMP/nameservers" >/dev/null 2>&1 || hth_unknown 'invalid nameserver response'
jq -e '.magicDNS | type == "boolean"' "$HTH_TEMP/preferences" >/dev/null 2>&1 || hth_unknown 'missing MagicDNS preference'
jq -e '.searchPaths | type == "array" and all(.[]; type == "string")' "$HTH_TEMP/searchpaths" >/dev/null 2>&1 || hth_unknown 'invalid search-domain response'
jq -e 'all(.[]; type == "array" and all(.[]; type == "string"))' "$HTH_TEMP/split-dns" >/dev/null 2>&1 || hth_unknown 'invalid split-DNS response'
jq -n --slurpfile servers "$HTH_TEMP/nameservers" --slurpfile preferences "$HTH_TEMP/preferences" \
  --slurpfile searches "$HTH_TEMP/searchpaths" --slurpfile split "$HTH_TEMP/split-dns" \
  '{nameservers:$servers[0].dns,magicDNS:$preferences[0].magicDNS,searchPaths:$searches[0].searchPaths,
    splitDNS:$split[0],coverage:"legacy read endpoints; review Override DNS, exit-node DNS and HTTPS/certificate settings separately"}' \
  > "$HTH_TEMP/evidence"
hth_save "$HTH_TEMP/evidence"
printf 'COLLECTED: DNS metadata snapshot; verify actual client resolution, override behavior and certificate disclosure separately.\n'
# HTH Guide Excerpt: end review-dns-configuration
