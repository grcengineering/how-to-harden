#!/usr/bin/env bash
# HTH Workato Control 7.03: Implement CI/CD Pipeline Integration
# Profile: L3 | NIST: SA-10, CM-3
# https://howtoharden.com/guides/workato/#73-implement-cicd-pipeline-integration

# HTH Guide Excerpt: begin api-list-recipes
# List all recipes in a project folder
curl -s "https://www.workato.com/api/recipes?folder_id=FOLDER_ID" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN" | \
  jq '.result[] | {id, name, running, version}'
# HTH Guide Excerpt: end api-list-recipes

# HTH Guide Excerpt: begin api-stop-recipe
# Stop a recipe before deployment
curl -s -X PUT "https://www.workato.com/api/recipes/RECIPE_ID/stop" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN"
# HTH Guide Excerpt: end api-stop-recipe

# HTH Guide Excerpt: begin api-start-recipe
# Start a recipe after deployment
curl -s -X PUT "https://www.workato.com/api/recipes/RECIPE_ID/start" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN"
# HTH Guide Excerpt: end api-start-recipe

# HTH Guide Excerpt: begin api-recipe-versions
# Get recipe versions (audit trail)
curl -s "https://www.workato.com/api/recipes/RECIPE_ID/versions" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN" | \
  jq '.result[] | {version, created_at, comment}'
# HTH Guide Excerpt: end api-recipe-versions
