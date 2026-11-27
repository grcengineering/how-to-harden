#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: confluent-cloud-1.1
#   guide: https://howtoharden.com/guides/confluent-cloud/#11-separate-workload-identities
#   profile: L1
#   mode: read-only
#   requires: confluent CLI authenticated to approved Cloud organization
# Source (reviewed 2026-11-27): https://docs.confluent.io/confluent-cli/current/command-reference/iam/service-account/index.html
# HTH Guide Excerpt: begin list-service-accounts
set +x
set -euo pipefail
fail() { printf 'UNKNOWN: %s\n' "$*" >&2; exit 2; }

command -v confluent >/dev/null || fail 'Confluent CLI is not installed'
confluent iam service-account list
# HTH Guide Excerpt: end list-service-accounts
