#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: openai-api-1.1
#   guide: https://howtoharden.com/guides/openai-api/#11-isolate-projects-and-minimize-effective-access
#   profile: L1
#   mode: read-only
#   requires: OPENAI_ADMIN_KEY, OPENAI_PROJECT_ID, curl, jq
# Source: https://developers.openai.com/api/reference/resources/admin/subresources/organization/subresources/projects/subresources/users/methods/list
# NIST 800-53 AC-2, AC-6. This roster is not all effective access.
source "$(dirname "$0")/common.sh"
openai_require_admin
: "${OPENAI_PROJECT_ID:?Set the project to assess}"
[[ "${OPENAI_PROJECT_ID}" =~ ^proj_[A-Za-z0-9_-]+$ ]] || exit 2
# HTH Guide Excerpt: begin project-membership
openai_list "/organization/projects/${OPENAI_PROJECT_ID}/users" |
  jq -c '{id, role, added_at}'
# Also review organization roles and group-derived roles in the dashboard;
# removing someone from this roster cannot cancel an organization-wide grant.
# HTH Guide Excerpt: end project-membership
