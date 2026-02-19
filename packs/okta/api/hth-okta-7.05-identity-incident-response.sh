#!/usr/bin/env bash
# HTH Okta Control 7.5: Identity Incident Response API Commands
# Profile: L2 | NIST: IR-4, IR-6
# https://howtoharden.com/guides/okta/#75-establish-identity-incident-response-procedures

# HTH Guide Excerpt: begin api-ir-suspend-admin
curl -X POST "https://${OKTA_DOMAIN}/api/v1/users/${USER_ID}/lifecycle/suspend" \
  -H "Authorization: SSWS ${OKTA_API_TOKEN}"
# HTH Guide Excerpt: end api-ir-suspend-admin

# HTH Guide Excerpt: begin api-ir-revoke-sessions
curl -X DELETE "https://${OKTA_DOMAIN}/api/v1/users/${USER_ID}/sessions" \
  -H "Authorization: SSWS ${OKTA_API_TOKEN}"
# HTH Guide Excerpt: end api-ir-revoke-sessions

# HTH Guide Excerpt: begin api-ir-audit-changes
curl -s -X GET "https://${OKTA_DOMAIN}/api/v1/logs?filter=actor.id+eq+%22${USER_ID}%22&since=${INCIDENT_START}" \
  -H "Authorization: SSWS ${OKTA_API_TOKEN}" | jq '.[] | {eventType, target, published}'
# HTH Guide Excerpt: end api-ir-audit-changes

# HTH Guide Excerpt: begin api-ir-deactivate-idp
curl -X POST "https://${OKTA_DOMAIN}/api/v1/idps/${IDP_ID}/lifecycle/deactivate" \
  -H "Authorization: SSWS ${OKTA_API_TOKEN}"
# HTH Guide Excerpt: end api-ir-deactivate-idp

# HTH Guide Excerpt: begin api-ir-delete-factor
curl -X DELETE "https://${OKTA_DOMAIN}/api/v1/users/${USER_ID}/factors/${FACTOR_ID}" \
  -H "Authorization: SSWS ${OKTA_API_TOKEN}"
# HTH Guide Excerpt: end api-ir-delete-factor
