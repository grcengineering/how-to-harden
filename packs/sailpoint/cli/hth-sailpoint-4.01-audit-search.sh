#!/usr/bin/env bash
# HTH SailPoint Control 4.1: Audit Logging and Reporting
# Profile: L1 | CIS Controls: 8.2 | NIST 800-53: AU-2, AU-3, AU-11
# https://howtoharden.com/guides/sailpoint/#41-audit-logging-and-reporting
#
# Interface: SailPoint CLI (`sail`, first-party) wrapping the Identity Security
# Cloud search API (events index).
#   CLI search command: https://developer.sailpoint.com/docs/tools/cli/search
#   Events index + fields (type, actor.name, created): SailPoint v3 search API
#   spec, https://github.com/sailpoint-oss/api-specs (idn/v3 search schemas)
# Prerequisite: `sail env create` configured for the tenant (OAuth or PAT auth);
# results are written as JSON files under ./search_results by default.

set -euo pipefail

# HTH Guide Excerpt: begin cli-search-provisioning-events
# Pull provisioning audit events from the events index, newest first.
# "type:PROVISIONING" is the documented example event query in SailPoint's
# v3 search API specification.
sail search query "type:PROVISIONING" --indices events --sort "-created"
# HTH Guide Excerpt: end cli-search-provisioning-events

# HTH Guide Excerpt: begin cli-search-support-signins
# Surface SailPoint Support / services sign-ins (control 1.3): support
# sessions are attributed to accounts in the slpt.support and slpt.services
# domains, which appear in the event actor field.
sail search query "actor.name:*slpt*" --indices events --sort "-created"
# HTH Guide Excerpt: end cli-search-support-signins

# HTH Guide Excerpt: begin cli-search-template-provisioning
# Built-in search template: export all provisioning events from the last
# 90 days to a local folder for scheduled retention beyond the tenant's
# self-service audit window (current month + 1 year).
sail search template all-provisioning-events-90-days --folderPath ./search_results
# HTH Guide Excerpt: end cli-search-template-provisioning
