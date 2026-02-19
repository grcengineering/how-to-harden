#!/usr/bin/env bash
# HTH GitHub Control 3.18: Automate SHA Pinning for GitHub Actions
# Profile: L2 | SLSA: Build L2
# https://howtoharden.com/guides/github/#31-restrict-third-party-github-actions-to-verified-creators-only

# HTH Guide Excerpt: begin api-pin-actions-automation
# Use https://github.com/mheap/pin-github-action
npx pin-github-action .github/workflows/*.yml
# HTH Guide Excerpt: end api-pin-actions-automation
