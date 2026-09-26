#!/usr/bin/env bash
# =============================================================================
# HTH Vercel Control 8.4: Verify Drain Delivery Signatures
# Profile Level: L1 (Crawl)
# Frameworks: NIST SC-8, SC-13, AU-9
# Source: https://howtoharden.com/guides/vercel/#84-verify-drain-signatures
# Rationale: Vercel Drains post JSON payloads signed with HMAC-SHA1 via
# x-vercel-signature. Receivers MUST verify the signature with a constant-time
# comparison to prevent timing attacks and accept only authentic deliveries.
# Reference: https://vercel.com/docs/drains/security
# API: POST /v1/drains/test (testDrain: "Validate the delivery configuration of
#      a Drain using sample events" -- sends sample events, creates no drain),
#      GET /v2/teams/{teamId} (hideIpAddresses*). Uses curl only, hence api/.
# =============================================================================

set -euo pipefail

# HTH Guide Excerpt: begin api

# --- Reference receiver (Node.js): verifies x-vercel-signature in constant time ---
RECEIVER="$(mktemp "${TMPDIR:-/tmp}/hth-drain-receiver.XXXXXX")"
cat > "${RECEIVER}" <<'JS'
// HTH reference Drain receiver with signature verification.
// See: https://vercel.com/docs/drains/security
const http = require('node:http');
const crypto = require('node:crypto');

const SECRET = process.env.VERCEL_DRAIN_SECRET;
if (!SECRET) {
  console.error('Set VERCEL_DRAIN_SECRET (matches the drain\'s rotatable secret).');
  process.exit(1);
}

const server = http.createServer((req, res) => {
  if (req.method !== 'POST') return res.writeHead(405).end();

  const chunks = [];
  req.on('data', c => chunks.push(c));
  req.on('end', () => {
    const body = Buffer.concat(chunks);
    const provided = req.headers['x-vercel-signature'];
    if (!provided || typeof provided !== 'string') {
      return res.writeHead(401).end('missing signature');
    }

    const expected = crypto
      .createHmac('sha1', SECRET)
      .update(body)
      .digest('hex');

    // Constant-time comparison — CRITICAL: prevents timing attacks.
    const a = Buffer.from(provided, 'utf8');
    const b = Buffer.from(expected, 'utf8');
    if (a.length !== b.length || !crypto.timingSafeEqual(a, b)) {
      return res.writeHead(401).end('invalid signature');
    }

    // TODO: forward verified payload to SIEM / object storage.
    process.stdout.write(`OK ${body.length} bytes\n`);
    res.writeHead(200).end('ok');
  });
});

server.listen(process.env.PORT || 8787, () => {
  console.log(`HTH drain receiver listening on :${process.env.PORT || 8787}`);
});
JS

echo "Reference receiver written to ${RECEIVER}"
echo "Run: VERCEL_DRAIN_SECRET=<drain-secret> node ${RECEIVER}"

# --- Validate the intended delivery config with sample events before going live ---
if [ -n "${VERCEL_TOKEN:-}" ] && [ -n "${VERCEL_TEAM_ID:-}" ] && [ -n "${VERCEL_DRAIN_URL:-}" ]; then
  echo ""
  echo "=== Testing drain delivery to ${VERCEL_DRAIN_URL} ==="
  curl -fsS -X POST \
    -H "Authorization: Bearer ${VERCEL_TOKEN}" \
    -H "Content-Type: application/json" \
    "https://api.vercel.com/v1/drains/test?teamId=${VERCEL_TEAM_ID}" \
    -d "$(jq -n --arg url "${VERCEL_DRAIN_URL}" '{
      schemas: { log: { version: "v1" } },
      delivery: { type: "http", endpoint: $url, encoding: "json", headers: {} }
    }')" | jq '.'
fi

# --- Ensure team-wide IP Address Visibility is disabled (GDPR hardening) ---
if [ -n "${VERCEL_TOKEN:-}" ] && [ -n "${VERCEL_TEAM_ID:-}" ]; then
  echo ""
  echo "=== Current team-level IP visibility settings ==="
  curl -fsS -H "Authorization: Bearer ${VERCEL_TOKEN}" \
    "https://api.vercel.com/v2/teams/${VERCEL_TEAM_ID}" | \
    jq '{hideIpAddresses, hideIpAddressesInLogDrains}'
fi

# HTH Guide Excerpt: end api
