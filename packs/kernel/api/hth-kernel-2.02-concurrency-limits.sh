#!/usr/bin/env bash
# Control: 2.2 Cap Browser Concurrency at Org and Project Level
# Profile Level: L2 (Walk)
# Frameworks: NIST 800-53 SC-6, CIS Controls v8 4, SOC 2 CC6.1/A1.1
# Guide: https://howtoharden.com/guides/kernel/
# Interface: Kernel REST API — /org/limits, /org/projects/{id}/limits
#   (OpenAPI: api.onkernel.com/spec.json)
set -euo pipefail

# HTH Guide Excerpt: begin org-default-cap
# Set the org-wide DEFAULT per-project concurrency cap. Applies to every
# project without an explicit override; cannot exceed the org's own limit.
# Setting the value to 0 REMOVES the default — treat 0 as a reviewed exception.
curl -sS -X PATCH https://api.onkernel.com/org/limits \
  -H "Authorization: Bearer ${KERNEL_ADMIN_KEY}" \
  -H "Content-Type: application/json" \
  -d '{ "default_project_max_concurrent_sessions": 10 }'

# Read back the effective org posture:
#   max_concurrent_sessions            — org ceiling (on-demand + pool reservations)
#   default_project_max_concurrent_sessions — the default cap you just set
curl -sS https://api.onkernel.com/org/limits \
  -H "Authorization: Bearer ${KERNEL_ADMIN_KEY}"
# HTH Guide Excerpt: end org-default-cap

# HTH Guide Excerpt: begin per-project-override
# Explicit override for a hot project. Omitted fields are left unchanged;
# a field set to 0 removes that project-level cap (org default applies).
curl -sS -X PATCH "https://api.onkernel.com/org/projects/proj_production_a1b2/limits" \
  -H "Authorization: Bearer ${KERNEL_ADMIN_KEY}" \
  -H "Content-Type: application/json" \
  -d '{ "max_concurrent_sessions": 25 }'

# Verify: null values mean no project-level cap (org limit applies).
curl -sS "https://api.onkernel.com/org/projects/proj_production_a1b2/limits" \
  -H "Authorization: Bearer ${KERNEL_ADMIN_KEY}"
# HTH Guide Excerpt: end per-project-override
