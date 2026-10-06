#!/usr/bin/env bash
# =============================================================================
# HTH Vercel Control 7.2: Harden TLS and Certificate Configuration
# Profile Level: L1 (Crawl)
# Frameworks: NIST SC-8, SC-13
# Source: https://howtoharden.com/guides/vercel/#72-harden-tls-and-certificate-configuration
# Checks: the negotiated protocol; TLS 1.0 and 1.1 are REFUSED (Validation 2);
#      HSTS max-age >= 1 year, plus includeSubDomains and preload when
#      HTH_HSTS_PRELOAD=1 (the L2 step); http:// answers 301/308; the team's
#      certificate inventory. CLI: vercel certs ls --scope <team> (20 per page,
#      paged with --next; the table goes to stdout, the paging hint to stderr).
# TLS verdicts are read from the s_client transcript, never its exit status:
#      LibreSSL (macOS /usr/bin/openssl) exits 1 after a completed handshake,
#      and OpenSSL 1.1+/3.x offers TLS 1.0/1.1 only at @SECLEVEL=0.
# Exit: 0 no finding, 1 finding, 2 a probe could not complete.
# =============================================================================

set -euo pipefail

: "${VERCEL_TOKEN:?Set VERCEL_TOKEN}"
: "${VERCEL_TEAM_ID:?Set VERCEL_TEAM_ID}"

# HTH Guide Excerpt: begin cli

DOMAIN="${1:-}"
if [ -z "${DOMAIN}" ]; then
  echo "Usage: $0 <your-domain.com>" >&2
  exit 2
fi
if ! [[ "${DOMAIN}" =~ ^[A-Za-z0-9][A-Za-z0-9.-]*$ ]]; then
  echo "ERROR: '${DOMAIN}' is not a DNS name (exit 2)." >&2
  exit 2
fi
FINDINGS=0
UNCHECKED=0

# OpenSSL will not offer TLS 1.0/1.1 above security level 0; LibreSSL offers
# them by default and rejects the @SECLEVEL syntax.
LEGACY_ARGS=()
case "$(openssl version 2>/dev/null)" in
  OpenSSL*) LEGACY_ARGS=(-cipher 'DEFAULT:@SECLEVEL=0') ;;
esac

# s_client transcript -> "<protocol> <cipher>" when a handshake completed, else "".
tls_result() {
  printf '%s\n' "$1" | awk '
    /^New, .*Cipher is / && c == "" { c = $0; sub(/.*Cipher is /, "", c) }
    /^ *Protocol *:/ && p == "" { p = $0; sub(/^ *Protocol *: */, "", p); sub(/ .*/, "", p) }
    END { if (c != "" && c != "(NONE)" && p != "") print p, c }'
}

echo "=== TLS Verification for ${DOMAIN} ==="

# --- Negotiated protocol and cipher ---
echo "--- Negotiated protocol and cipher ---"
tls_out="$(openssl s_client -connect "${DOMAIN}:443" -servername "${DOMAIN}" < /dev/null 2>&1)" || true
negotiated="$(tls_result "${tls_out}")"
case "${negotiated%% *}" in
  "") echo "  UNCHECKED: no TLS handshake completed with ${DOMAIN}:443"; UNCHECKED=1 ;;
  SSLv3|TLSv1|TLSv1.1) echo "  WARNING: the default handshake negotiated ${negotiated}"; FINDINGS=1 ;;
  *) echo "  OK: ${negotiated}" ;;
esac

# --- TLS 1.0 / 1.1 must be refused by the server (Validation 2) ---
echo "--- Legacy protocols (must be refused) ---"
for proto in tls1 tls1_1; do
  legacy_out="$(openssl s_client -connect "${DOMAIN}:443" -servername "${DOMAIN}" "-${proto}" \
    ${LEGACY_ARGS[@]+"${LEGACY_ARGS[@]}"} < /dev/null 2>&1)" || true
  accepted="$(tls_result "${legacy_out}")"
  if [ -n "${accepted}" ]; then
    echo "  WARNING: ${DOMAIN} completed a ${proto} handshake (${accepted})"
    FINDINGS=1
  elif printf '%s\n' "${legacy_out}" | \
       grep -iE 'alert (protocol version|handshake failure)|unsupported protocol|wrong (ssl )?version' > /dev/null; then
    echo "  OK: ${proto} refused by the server"
  else
    # e.g. the local openssl cannot offer ${proto} ("no protocols available")
    echo "  UNCHECKED: ${proto} probe inconclusive"
    UNCHECKED=1
  fi
done

# --- HSTS ---
echo "--- HSTS ---"
if headers="$(curl -sSI --max-time 15 "https://${DOMAIN}" 2>/dev/null)"; then
  hsts="$(printf '%s\n' "${headers}" | tr -d '\r' | awk '
    tolower($0) ~ /^strict-transport-security:/ && v == "" { v = $0; sub(/^[^:]*: */, "", v) }
    END { print v }')"
  max_age="$(printf '%s\n' "${hsts}" | awk '
    match(tolower($0), /max-age=[0-9]+/) { print substr($0, RSTART + 8, RLENGTH - 8) }')"
  hsts_lc="$(printf '%s' "${hsts}" | tr '[:upper:]' '[:lower:]')"
  if [ -z "${hsts}" ]; then
    echo "  WARNING: no Strict-Transport-Security header"
    FINDINGS=1
  elif [ -z "${max_age}" ] || [ "${max_age}" -lt 31536000 ]; then
    echo "  WARNING: HSTS max-age is below one year: ${hsts}"
    FINDINGS=1
  elif [ "${HTH_HSTS_PRELOAD:-0}" = "1" ] && \
       { [[ "${hsts_lc}" != *includesubdomains* ]] || [[ "${hsts_lc}" != *preload* ]]; }; then
    echo "  WARNING: L2 HSTS needs includeSubDomains and preload: ${hsts}"
    FINDINGS=1
  else
    echo "  OK: ${hsts}"
  fi
else
  echo "  UNCHECKED: HEAD https://${DOMAIN} failed"
  UNCHECKED=1
fi

# --- HTTP to HTTPS redirect (curl prints 000 itself when it cannot connect) ---
echo "--- HTTP redirect ---"
redirect="$(curl -s -o /dev/null -w '%{http_code}' --max-time 15 "http://${DOMAIN}" 2>/dev/null)" || true
[ -n "${redirect}" ] || redirect="000"
case "${redirect}" in
  301|308) echo "  OK: HTTP redirects to HTTPS (${redirect})" ;;
  000) echo "  UNCHECKED: http://${DOMAIN} did not answer"; UNCHECKED=1 ;;
  *) echo "  WARNING: HTTP returned ${redirect} -- expected a 308 redirect"; FINDINGS=1 ;;
esac

# --- Issue custom certificate (L3, MUTATING -- run deliberately) ---
# vercel certs issue "${DOMAIN}" --scope "${VERCEL_TEAM_ID}"

# --- Certificate inventory for the TEAM, every page ---
echo ""
echo "=== Certificate Inventory ==="
VC=(vercel --scope "${VERCEL_TEAM_ID}")
NEXT=""
COMPLETE=0
ERR_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-certs.XXXXXX")"
trap 'rm -f "${ERR_FILE}"' EXIT
for _page in $(seq 1 50); do
  NEXT_ARGS=()
  [ -z "${NEXT}" ] || NEXT_ARGS=(--next "${NEXT}")
  if ! "${VC[@]}" certs ls ${NEXT_ARGS[@]+"${NEXT_ARGS[@]}"} 2> "${ERR_FILE}"; then
    cat "${ERR_FILE}" >&2
    echo "ERROR: vercel certs ls failed -- the certificate inventory is incomplete (exit 2)." >&2
    exit 2
  fi
  cat "${ERR_FILE}" >&2
  NEXT="$(grep -oE -- '--next [0-9]+' "${ERR_FILE}" | awk '{ n = $2 } END { print n }')" || true
  if [ -z "${NEXT}" ]; then
    COMPLETE=1
    break
  fi
done
if [ "${COMPLETE}" -ne 1 ]; then
  echo "ERROR: more than 50 pages of certificates -- the inventory is incomplete (exit 2)." >&2
  exit 2
fi

echo ""
echo "Findings: ${FINDINGS}; probes that could not complete: ${UNCHECKED}"
if [ "${UNCHECKED}" -ne 0 ]; then
  exit 2
fi
exit "${FINDINGS}"

# HTH Guide Excerpt: end cli
