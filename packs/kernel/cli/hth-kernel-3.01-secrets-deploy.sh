#!/usr/bin/env bash
# Control: 3.1 Inject App Secrets at Deploy Time, Never in Code
# Profile Level: L1 (Crawl)
# Frameworks: NIST 800-53 IA-5(7)/SA-3, CIS Controls v8 16, SOC 2 CC6.1
# Guide: https://howtoharden.com/guides/kernel/
# Interface: Kernel CLI (first-party) — https://www.kernel.sh/docs/apps/secrets
set -euo pipefail

# HTH Guide Excerpt: begin deploy-with-secrets
# Individual values (from your secret manager, via the shell environment):
kernel deploy my_app.ts --env OPENAI_API_KEY="${OPENAI_API_KEY}"

# Or load a local .env file that is excluded from version control:
kernel deploy my_app.ts --env-file .env

# App code reads injected values at runtime via the standard environment:
#   TypeScript: process.env.OPENAI_API_KEY
#   Python:     os.environ["OPENAI_API_KEY"]
# HTH Guide Excerpt: end deploy-with-secrets

# HTH Guide Excerpt: begin repo-hygiene-check
# Guard the choke point: .env must never be committed, and app source
# must not embed key material.
grep -qxF '.env' .gitignore || echo 'MISSING: add .env to .gitignore'
git grep -nE '(sk-[A-Za-z0-9]|api[_-]?key\s*=\s*["'"'"'][^"'"'"']{8,})' -- '*.ts' '*.py' \
  && echo 'FAIL: possible hardcoded secrets above' || echo 'OK: no hardcoded secrets found'
# HTH Guide Excerpt: end repo-hygiene-check
