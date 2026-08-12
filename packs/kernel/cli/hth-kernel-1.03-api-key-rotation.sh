#!/usr/bin/env bash
# Control: 1.3 Rotate API Keys with Bounded Grace Periods
# Profile Level: L1 (Crawl)
# Frameworks: NIST 800-53 IA-5, CIS Controls v8 5, SOC 2 CC6.1
# Guide: https://howtoharden.com/guides/kernel/
# Interface: Kernel CLI (first-party) — https://www.kernel.sh/docs/reference/cli/api-keys
set -euo pipefail

# HTH Guide Excerpt: begin routine-rotation
# Routine rotation: issues a new key (same name and project binding),
# old key stays valid for the grace period so in-flight callers can swap.
# --days-to-expire: lifetime of the NEW key
# --expire-in-days: grace period for the OLD key (default 7)
kernel api-keys rotate key_01jwv4tn5m8k3q2v7x9p0a1bc2 \
  --days-to-expire 90 \
  --expire-in-days 7 \
  --yes --output json
# HTH Guide Excerpt: end routine-rotation

# HTH Guide Excerpt: begin emergency-revocation
# Confirmed leak: rotate with an immediate kill of the old key.
kernel api-keys rotate key_01jwv4tn5m8k3q2v7x9p0a1bc2 \
  --expire-in-days 0 \
  --yes --output json

# Or delete outright. A key cannot delete itself — authenticate
# with a DIFFERENT (admin) key for the deletion.
kernel api-keys delete key_01jwv4tn5m8k3q2v7x9p0a1bc2 --yes
# HTH Guide Excerpt: end emergency-revocation
