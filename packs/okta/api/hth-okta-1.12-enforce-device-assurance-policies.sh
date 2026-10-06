#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: okta-1.12
#   guide:   https://howtoharden.com/guides/okta/#112-enforce-device-assurance-policies
#   profile: L2
#   mode:    read-only
#   requires: OKTA_DOMAIN, OKTA_API_TOKEN(SSWS token owned by a Read-only Administrator), HTH_PROFILE_LEVEL(optional)
# HTH Okta Control 1.12: Enforce Device Assurance Policies
# Profile: L2 | NIST: CM-6, IA-3, SI-2
# https://howtoharden.com/guides/okta/#112-enforce-device-assurance-policies
#
# Read-only audit. A token owned by a Read-Only Administrator is sufficient.
# Field names follow the Okta Management API DeviceAssurance platform schemas
# (osVersion, diskEncryptionType, screenLockType, secureHardwarePresent, jailbreak).
source "$(dirname "$0")/common.sh"

banner "1.12: Enforce Device Assurance Policies"

should_apply 2 || { increment_skipped; summary; exit 0; }
info "1.12 Auditing device assurance policies..."

# HTH Guide Excerpt: begin api-list-device-assurance
# One policy per platform, each with its posture requirements (a failed read stops the pack)
POLICIES=$(okta_get "/api/v1/device-assurances")
printf '%s' "${POLICIES}" | jq -r '.[] | "  - \(.name) [\(.platform)]: osVersion=\(.osVersion.minimum // .osVersion.dynamicVersionRequirement.type // "none"), diskEncryption=\(.diskEncryptionType.include // [] | join("+") | if . == "" then "none" else . end), screenLock=\(.screenLockType.include // [] | join("+") | if . == "" then "none" else . end), secureHardware=\(if has("secureHardwarePresent") then .secureHardwarePresent else "n/a" end),jailbreak=\(if has("jailbreak") then .jailbreak else "n/a" end)"'
# HTH Guide Excerpt: end api-list-device-assurance

COVERED=$(printf '%s' "${POLICIES}" | jq -r '[.[].platform] | unique | join(" ")')
info "1.12 Platforms with a device assurance policy: ${COVERED:-none}"

MISSING=""
for PLATFORM in ANDROID CHROMEOS IOS MACOS WINDOWS; do
  case " ${COVERED} " in
    *" ${PLATFORM} "*) ;;
    *) MISSING="${MISSING} ${PLATFORM}" ;;
  esac
done

if [ -n "${MISSING}" ]; then
  warn "1.12 No device assurance policy for:${MISSING} -- add one for every platform in your fleet"
else
  pass "1.12 Every platform has a device assurance policy"
fi
increment_applied

summary
