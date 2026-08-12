#!/usr/bin/env bash
# Control: 4.5 Cryptographically Sign Agent Traffic (Web Bot Auth)
# Profile Level: L3 (Run)
# Frameworks: NIST 800-53 IA-9, CIS Controls v8 13, SOC 2 CC6.1
# Guide: https://howtoharden.com/guides/kernel/
# Interface: Kernel CLI (first-party) — https://www.kernel.sh/docs/browsers/bot-detection/web-bot-auth
set -euo pipefail

# HTH Guide Excerpt: begin build-signing-extension
# Prerequisites (per the Web Bot Auth doc):
#   1. An Ed25519 JWK file containing the public (x) AND private (d)
#      components — guard the private component like a signing CA key.
#   2. Your public keys published in JWKS form at:
#      https://yourdomain.com/.well-known/http-message-signatures-directory
#
# Build the signing extension. Signed requests carry RFC 9421 headers:
# Signature, Signature-Input, and Signature-Agent (your key directory URL).
kernel extensions build-web-bot-auth \
  --key ./my-key.jwk \
  --signature-agent https://yourdomain.com

# Attach the signing extension to fleet browsers:
kernel browsers create --extension my-web-bot-auth
# Services like Cloudflare and Vercel verify these signatures against your
# published public key, confirming the request came from YOUR agent.
# HTH Guide Excerpt: end build-signing-extension
