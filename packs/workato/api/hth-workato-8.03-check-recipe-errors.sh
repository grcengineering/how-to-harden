#!/usr/bin/env bash
# HTH Workato Control 8.03: Configure Recipe Error Monitoring
# Profile: L1 | NIST: CA-7
# https://howtoharden.com/guides/workato/#83-configure-recipe-error-monitoring

# HTH Guide Excerpt: begin api-list-active-recipes
# List recipes with recent errors
curl -s "https://www.workato.com/api/recipes?active=true" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN" | \
  jq '.result[] | select(.last_run_at != null) | {
    id, name,
    last_run: .last_run_at,
    running: .running
  }'
# HTH Guide Excerpt: end api-list-active-recipes

# HTH Guide Excerpt: begin api-get-failed-jobs
# Get recent job history for a specific recipe
curl -s "https://www.workato.com/api/recipes/RECIPE_ID/jobs?status=failed" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN" | \
  jq '.result[] | {id, started_at, completed_at, error}'
# HTH Guide Excerpt: end api-get-failed-jobs
