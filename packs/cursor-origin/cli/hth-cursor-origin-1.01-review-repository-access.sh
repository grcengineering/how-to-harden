#!/usr/bin/env bash
# HTH Pack Contract: v1
# control: cursor-origin-1.1
# guide: https://howtoharden.com/guides/cursor-origin/#11-limit-codebase-and-repository-access
# profile: L1
# mode: read-only
# requires: origin(early beta); HTH_ALLOW_READONLY=1; ORIGIN_REPO(owner/repo)
# NIST AC-3/AC-6. Source: https://cursor.com/docs/origin/cli/reference/commands (2026-11-05)
# Usage: HTH_ALLOW_READONLY=1 ORIGIN_REPO=owner/repo bash <file>
# Human-readable evidence only. No token-printing, login, install, grant or write commands.
set -euo pipefail
[[ ${HTH_ALLOW_READONLY:-} == 1 ]] || { echo 'PRECONDITION: set HTH_ALLOW_READONLY=1 after authorizing a read'; exit 2; }
[[ ${ORIGIN_REPO:-} =~ ^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$ ]] || { echo 'PRECONDITION: explicit owner/repo required'; exit 2; }
[[ -z ${CURSOR_ORIGIN_ENDPOINT:-} ]] || { echo 'PRECONDITION: unset custom Origin endpoint before using stored credentials'; exit 2; }
command -v origin >/dev/null || { echo 'PRECONDITION: install and authenticate the official Origin CLI separately'; exit 2; }
# HTH Guide Excerpt: begin review-direct-and-inherited-access
origin repo access list -R "$ORIGIN_REPO"
origin namespace access list "${ORIGIN_REPO%%/*}"
echo 'REVIEW: repository and namespace grants require reconciliation; successful reads are not a compliance result.'
# HTH Guide Excerpt: end review-direct-and-inherited-access
