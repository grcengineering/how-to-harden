#!/usr/bin/env bash
# HTH GitHub Control 6.01: Manual Dependency Review
# Profile: L1 | SLSA: Build L2
# https://howtoharden.com/guides/github/#61-enable-dependency-review-for-pull-requests
source "$(dirname "$0")/common.sh"

banner "6.01: Manual Dependency Review"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "6.01 Performing manual dependency review..."

# HTH Guide Excerpt: begin api-manual-dependency-review
# Manual dependency review
gh api /repos/{owner}/{repo}/dependency-graph/compare/main...feature-branch
# HTH Guide Excerpt: end api-manual-dependency-review

# HTH Guide Excerpt: begin api-check-pr-vulnerabilities
# Check PR for new vulnerabilities
gh pr view 123 --json reviews
# HTH Guide Excerpt: end api-check-pr-vulnerabilities

increment_applied
summary
