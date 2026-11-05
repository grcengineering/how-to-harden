#!/usr/bin/env bash
# Shared candidate emitter, not an installer. Download the whole vendor directory.
# Sources: https://tailscale.com/docs/features/tailscale-system-policies
# https://tailscale.com/docs/integrations/mdm/{linux,windows-mdm,mac}
set +x
set -Eeuo pipefail
# shellcheck source=../common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

hth_policy_init() {
  hth_init "$1"
  local desktop_minor="$2" linux_minor="$3" version="${TAILSCALE_CLIENT_VERSION:-}" minimum
  case "${TAILSCALE_PLATFORM:-}" in
    windows|macos-standalone) minimum="$desktop_minor" ;;
    linux) minimum="$linux_minor" ;;
    *) hth_unknown 'TAILSCALE_PLATFORM must be windows, macos-standalone or linux' ;;
  esac
  [[ "$version" =~ ^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$ ]] ||
    hth_unknown 'set the installed stable TAILSCALE_CLIENT_VERSION as major.minor.patch'
  local major=$((10#${BASH_REMATCH[1]})) minor=$((10#${BASH_REMATCH[2]}))
  (( major > 1 || (major == 1 && minor >= minimum) )) ||
    hth_unknown "this candidate requires Tailscale 1.${minimum}.0 or later on the selected platform"
}

hth_policy_emit() {
  local settings="$1"
  # Only fixed keys/values built by the calling pack enter the platform format.
  case "$TAILSCALE_PLATFORM" in
    linux) jq . "$settings" > "$HTH_TEMP/candidate" ;;
    windows)
      {
        printf 'Windows Registry Editor Version 5.00\r\n\r\n[HKEY_LOCAL_MACHINE\\SOFTWARE\\Policies\\Tailscale]\r\n'
        jq -r 'to_entries[] | if (.value|type) == "boolean"
          then "\"\(.key)\"=dword:\(if .value then "00000001" else "00000000" end)"
          else "\"\(.key)\"=\(.value|tojson)" end' "$settings" |
          while IFS= read -r line; do printf '%s\r\n' "$line"; done
      } > "$HTH_TEMP/candidate" ;;
    macos-standalone)
      {
        printf '%s\n' '<?xml version="1.0" encoding="UTF-8"?>' \
          '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' \
          '<!-- Settings fragment for managed preference domain io.tailscale.ipn.macsys; not a complete configuration profile. -->' \
          '<plist version="1.0"><dict>'
        jq -r 'to_entries[] | "<key>\(.key|@html)</key>\n" +
          (if (.value|type) == "boolean" then (if .value then "<true/>" else "<false/>" end)
           else "<string>\(.value|@html)</string>" end)' "$settings"
        printf '%s\n' '</dict></plist>'
      } > "$HTH_TEMP/candidate" ;;
  esac
  hth_save "$HTH_TEMP/candidate"
  printf 'GENERATED-CANDIDATE: settings fragment only; review, merge and deploy through the existing management owner. Nothing installed or restarted.\n'
}
