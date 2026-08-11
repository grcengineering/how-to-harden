#!/usr/bin/env bash
# Control: 4.2 Vet, Pin, and Checksum Browser Extensions
# Profile Level: L2 (Hardened)
# Frameworks: NIST 800-53 CM-11, CIS Controls v8 2, SOC 2 CC8.1
# Guide: https://howtoharden.com/guides/kernel/
# Interface: Kernel CLI (first-party) + REST API —
#   https://www.kernel.sh/docs/browsers/extensions
set -euo pipefail

# HTH Guide Excerpt: begin vet-and-upload
# 1. Fetch the exact unpacked artifact for review (Web Store source):
kernel extensions download-web-store \
  "https://chromewebstore.google.com/detail/EXTENSION_ID" --to ./candidate-extension

# 2. REVIEW ./candidate-extension: manifest permissions, code provenance.
#    Only after review, register the artifact you vetted:
kernel extensions upload ./candidate-extension --name approved-ext-v1

# 3. Record its checksum in your approval log. Metadata includes a
#    lowercase hex SHA-256 checksum when available.
curl -sS "https://api.onkernel.com/extensions/approved-ext-v1/metadata" \
  -H "Authorization: Bearer ${KERNEL_API_KEY}"
# HTH Guide Excerpt: end vet-and-upload

# HTH Guide Excerpt: begin reconcile-fleet
# Cadence check: enumerate extensions in the project and reconcile each
# checksum against the approval record.
curl -sS "https://api.onkernel.com/extensions" \
  -H "Authorization: Bearer ${KERNEL_API_KEY}"

# Load extensions into browsers BY NAME so what runs is what you vetted:
kernel browsers create --extension approved-ext-v1
# HTH Guide Excerpt: end reconcile-fleet
