#!/usr/bin/env bash
# HTH GitHub Control 2.07: Monitor Dependabot and Secret Scanning Alerts
# Profile: L1 | NIST: RA-5, SA-11
# https://howtoharden.com/guides/github/#22-enable-security-features-dependabot-code-scanning-secret-scanning
source "$(dirname "$0")/common.sh"

banner "2.07: Monitor Security Alerts"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "2.07 Monitoring security alerts for ${GITHUB_ORG}..."

# HTH Guide Excerpt: begin api-list-dependabot-alerts
# List critical/high severity alerts
gh api /orgs/{org}/dependabot/alerts --jq '.[] | select(.severity == "critical" or .severity == "high") | {repo: .repository.name, package: .security_advisory.package.name, severity: .severity}'
# HTH Guide Excerpt: end api-list-dependabot-alerts

# HTH Guide Excerpt: begin api-list-secret-scanning-alerts
# List active secret alerts
gh api /orgs/{org}/secret-scanning/alerts?state=open --jq '.[] | {repo: .repository.name, secret_type: .secret_type, created_at: .created_at}'
# HTH Guide Excerpt: end api-list-secret-scanning-alerts

increment_applied
summary
