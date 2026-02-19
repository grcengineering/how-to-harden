#!/usr/bin/env bash
# HTH Workato Control 2.06: Implement Privilege Access Reviews
# Profile: L2 | NIST: AC-2(3)
# https://howtoharden.com/guides/workato/#26-implement-privilege-access-reviews

# HTH Guide Excerpt: begin api-export-access-review
# Export all collaborators with roles for access review
curl -s "https://www.workato.com/api/managed_users" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN" | \
  jq -r '["Name","Email","Role","External ID"],
    (.result[] | [.name, .email, .role_name, .external_id]) |
    @csv' > workato_access_review_$(date +%Y%m%d).csv

echo "Access review export complete. Review and verify each entry."
# HTH Guide Excerpt: end api-export-access-review
