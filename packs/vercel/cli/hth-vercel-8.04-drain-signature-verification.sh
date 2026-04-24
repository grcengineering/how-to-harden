#!/usr/bin/env bash
# =============================================================================
# HTH Vercel Control 8.4: Verify Drain Delivery Signatures
# Profile Level: L1 (Baseline)
# Frameworks: NIST SC-8, SC-13, AU-9
# Source: https://howtoharden.com/guides/vercel/#84-verify-drain-signatures
# Rationale: Vercel Drains post JSON payloads signed with HMAC-SHA1 via
# x-vercel-signature. Receivers MUST verify the signature with a constant-time
# comparison to prevent timing attacks and accept only authentic deliveries.
# Reference: https://vercel.com/docs/drains/security
# =============================================================================

set -euo pipefail

# HTH Guide Excerpt: begin cli

# --- Reference receiver (Node.js): verifies x-vercel-signature in constant time ---
# Run: node hth-drain-receiver.js  (expects VERCEL_DRAIN_SECRET in env)
cat > /tmp/hth-drain-receiver.js <<'JS'
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

echo "Reference receiver written to /tmp/hth-drain-receiver.js"
echo "Run: VERCEL_DRAIN_SECRET=<drain-secret> node /tmp/hth-drain-receiver.js"

# --- Validate an existing drain's delivery config before going live ---
if [ -n "${VERCEL_TOKEN:-}" ] && [ -n "${VERCEL_TEAM_ID:-}" ] && [ -n "${VERCEL_DRAIN_URL:-}" ]; then
  echo ""
  echo "=== Validating drain delivery to ${VERCEL_DRAIN_URL} ==="
  curl -s -X POST \
    -H "Authorization: Bearer ${VERCEL_TOKEN}" \
    -H "Content-Type: application/json" \
    "https://api.vercel.com/v1/drains/validate?teamId=${VERCEL_TEAM_ID}" \
    -d "$(jq -n --arg url "${VERCEL_DRAIN_URL}" '{
      schemas: { log: { version: "v1" } },
      delivery: { url: $url }
    }')" | jq '.'
fi

# --- Ensure team-wide IP Address Visibility is disabled (GDPR hardening) ---
if [ -n "${VERCEL_TOKEN:-}" ] && [ -n "${VERCEL_TEAM_ID:-}" ]; then
  echo ""
  echo "=== Current team-level IP visibility settings ==="
  curl -s -H "Authorization: Bearer ${VERCEL_TOKEN}" \
    "https://api.vercel.com/v2/teams/${VERCEL_TEAM_ID}" | \
    jq '{
      hideIpAddresses: .hideIpAddresses,
      hideIpAddressesInLogDrains: .hideIpAddressesInLogDrains
    }'
fi

# HTH Guide Excerpt: end cli
