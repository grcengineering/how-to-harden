#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: guidewire-cloud-1.3
#   guide: https://howtoharden.com/guides/guidewire-cloud/#13-require-merge-review-for-managed-application-repositories
#   profile: L1
#   mode: read-only
#   requires: bash, curl, jq, approved regional Repository Settings and scms.mergechecks.read token
# Source (checked 2026-11-27): https://docs.guidewire.com/cloud/console/repositorysettingsapi/guide-merge-checks/
# Review locally; protect evidence from unnecessary disclosure.

# HTH Guide Excerpt: begin guidewire-cloud-evidence
set +x
set -euo pipefail
: "${HTH_GUIDEWIRE_REGION:?Set the approved Guidewire region.}"
: "${HTH_GUIDEWIRE_TENANT:?Set the approved tenant ID.}"
: "${HTH_GUIDEWIRE_STAR_SYSTEM:?Set the approved star system ID.}"
: "${HTH_GUIDEWIRE_REPOSITORY:?Set the approved repository name.}"
: "${HTH_GUIDEWIRE_TOKEN:?Set the region-appropriate read-only token.}"
case "$HTH_GUIDEWIRE_REGION" in
  AMER) cluster=andromeda;; BRAZIL) cluster=sculptor;; CANADA) cluster=butterfly;;
  EMEA) cluster=cartwheel;; SWITZERLAND) cluster=whirlpool;; APAC) cluster=circinus;; JAPAN) cluster=milkyway;;
  *) printf 'Unsupported Guidewire region.\n' >&2; exit 2;;
esac
part='^[A-Za-z0-9][A-Za-z0-9_.-]{0,127}$'
[[ "$HTH_GUIDEWIRE_TENANT" =~ $part && "$HTH_GUIDEWIRE_STAR_SYSTEM" =~ $part &&
   "$HTH_GUIDEWIRE_REPOSITORY" =~ $part && "$HTH_GUIDEWIRE_TOKEN" =~ ^[A-Za-z0-9._~+/=-]+$ ]] ||
  { printf 'Invalid repository scope or access token.\n' >&2; exit 2; }
printf 'Authorization: Bearer %s\n' "$HTH_GUIDEWIRE_TOKEN" |
  curl -q --silent --show-error --fail --proto '=https' --connect-timeout 10 --max-time 30 --header @-     "https://scmservice.api.omega2-$cluster.guidewire.net/api/v1/tenants/$HTH_GUIDEWIRE_TENANT/starsystems/$HTH_GUIDEWIRE_STAR_SYSTEM/repository/$HTH_GUIDEWIRE_REPOSITORY/merge-checks" |
  jq -es '
    if length != 1 or (.[0] | type) != "array" then error("Expected one merge-check list") else .[0] end
    | map(select(.key == "MINIMUM_APPROVALS" or .key == "MINIMUM_SUCCESSFUL_BUILDS")) | sort_by(.key)
    | if (map(.key) != ["MINIMUM_APPROVALS","MINIMUM_SUCCESSFUL_BUILDS"]) or
      (all(.[]; (.enabled | type) == "boolean" and
        (.scope.type | IN("PROJECT","REPOSITORY")) and
        (if .enabled then (.settings.requiredCount | type) == "number" and
          .settings.requiredCount > 0 and (.settings.requiredCount | floor) == .settings.requiredCount
         else true end)) | not)
      then error("Missing or malformed approval/build settings")
      else map({key,enabled,scope:.scope.type,required_count:(if .enabled then .settings.requiredCount else null end)}) end'
# HTH Guide Excerpt: end guidewire-cloud-evidence
