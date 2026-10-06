#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: cursor-11.2
#   guide:   https://howtoharden.com/guides/cursor/#112-enforce-organizational-policies-via-mdm
#   profile: L3
#   mode:    read-only
#   requires: jq; HTH_ALLOWED_TEAM_IDS (emit only), HTH_ALLOWED_EXTENSIONS(optional JSON string, emit only); plutil on macOS
# =============================================================================
# HTH Cursor Control 11.2: Enforce Organizational Policies via MDM
# Profile Level: L3 (Run)
# Source: https://howtoharden.com/guides/cursor/#112-enforce-organizational-policies-via-mdm
#
# Policy keys and file formats are Cursor's
# (https://cursor.com/docs/enterprise/deployment-patterns#mdm-configuration):
#   Linux    ~/.cursor/policy.json (Cursor 2.0+), keys at the top level;
#            AllowedExtensions is a JSON *string*, not an object
#   macOS    configuration profile, payload domain com.todesktop.230313mzl4w4u92
#            (production channel). macOS writes a profile's preferences to
#            /Library/Managed Preferences/, which is what the verify step reads.
#   Windows  ADMX Group Policy (not covered here — use your GPO tooling)
# Invalid policy JSON is ignored by Cursor ("runs without policy restrictions"),
# which is why the verify step parses the file instead of only testing it exists.
#
# Usage:  emit   -> print a Linux policy.json for your config-management tool
#         verify -> check the policy actually present on this machine
# Exit codes: 0 ok | 1 policy missing or weak | 2 precondition / unsupported OS
# =============================================================================

set -uo pipefail
command -v jq >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }
ACTION="${1:-verify}"

# HTH Guide Excerpt: begin cli-emit-linux-policy
# Print a Linux ~/.cursor/policy.json: pin logins to your team(s) and force Workspace Trust
if [ "$ACTION" = "emit" ]; then
  : "${HTH_ALLOWED_TEAM_IDS:?set HTH_ALLOWED_TEAM_IDS — comma-separated team IDs (cursor.com/dashboard, click the team name)}"
  EXT="${HTH_ALLOWED_EXTENSIONS:-}"
  if [ -n "$EXT" ] && ! printf '%s' "$EXT" | jq -e 'type == "object"' >/dev/null 2>&1; then
    echo "ERROR: HTH_ALLOWED_EXTENSIONS must be a JSON object, e.g. {\"anysphere\": true, \"github\": true}" >&2
    exit 2
  fi
  jq -n --arg team "$HTH_ALLOWED_TEAM_IDS" --arg ext "$EXT" '
    {AllowedTeamId: $team, WorkspaceTrustEnabled: true}
    + (if $ext == "" then {} else {AllowedExtensions: $ext} end)'
  exit 0
fi
# HTH Guide Excerpt: end cli-emit-linux-policy

# HTH Guide Excerpt: begin cli-verify-mdm-policy
# Verify the Cursor policy in force on this machine
TEAM=""; TRUST=""
case "$(uname -s)" in
  Linux)
    POLICY="${HOME}/.cursor/policy.json"
    [ -f "$POLICY" ] || { echo "FAIL: no $POLICY — Cursor runs without policy restrictions"; exit 1; }
    jq -e 'type == "object"' "$POLICY" >/dev/null 2>&1 || { echo "FAIL: $POLICY is not valid JSON — Cursor ignores it"; exit 1; }
    TEAM=$(jq -r '.AllowedTeamId // ""' "$POLICY")
    TRUST=$(jq -r '.WorkspaceTrustEnabled // false' "$POLICY")
    ;;
  Darwin)
    DOMAIN="com.todesktop.230313mzl4w4u92"
    PLIST=""
    for P in "/Library/Managed Preferences/${USER:-$(id -un)}/${DOMAIN}.plist" "/Library/Managed Preferences/${DOMAIN}.plist"; do
      [ -f "$P" ] && { PLIST="$P"; break; }
    done
    [ -n "$PLIST" ] || { echo "FAIL: no managed Cursor profile ($DOMAIN) installed on this Mac"; exit 1; }
    TEAM=$(plutil -extract AllowedTeamId raw -o - "$PLIST" 2>/dev/null || true)
    TRUST=$(plutil -extract WorkspaceTrustEnabled raw -o - "$PLIST" 2>/dev/null || true)
    ;;
  *) echo "UNSUPPORTED: verify Windows Group Policy with your GPO tooling"; exit 2 ;;
esac

FAILS=0
if [ -n "$TEAM" ]; then echo "  PASS: AllowedTeamId=$TEAM"; else echo "  FAIL: AllowedTeamId not set — personal accounts can sign in"; FAILS=1; fi
if [ "$TRUST" = "true" ]; then echo "  PASS: WorkspaceTrustEnabled=true"; else echo "  FAIL: WorkspaceTrustEnabled is not true"; FAILS=1; fi
exit "$FAILS"
# HTH Guide Excerpt: end cli-verify-mdm-policy
