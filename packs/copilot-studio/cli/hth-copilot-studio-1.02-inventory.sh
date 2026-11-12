#!/usr/bin/env bash
set -euo pipefail
# 1.2 Production agent inventory; L1 (Crawl); NIST CM-8/AC-6.
# Guide: https://howtoharden.com/guides/copilot-studio/
# Available: https://learn.microsoft.com/en-us/power-platform/developer/cli/reference/copilot#pac-copilot-list
# Authenticated PAC profile required. Read only; no publish/push/import.
# HTH Guide Excerpt: begin inventory
: "${DATAVERSE_ENVIRONMENT:?Set an explicit environment GUID or HTTPS URL}"
command -v pac >/dev/null || { echo 'Install the official Power Platform CLI first' >&2; exit 1; }
pac copilot list --environment "$DATAVERSE_ENVIRONMENT"
# HTH Guide Excerpt: end inventory
