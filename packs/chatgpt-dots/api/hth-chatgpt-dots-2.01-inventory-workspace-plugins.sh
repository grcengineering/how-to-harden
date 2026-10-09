#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: chatgpt-dots-2.1
#   guide:   https://howtoharden.com/guides/chatgpt-dots/#21-restrict-the-app-connections-and-actions-dots-inherit-to-read-only-by-default
#   profile: L1
#   mode:    read-only
#   requires: CHATGPT_ADMIN_KEY(workspace Admin key with chatgpt.enterprise.compliance_export read — see TRAP 3), CHATGPT_WORKSPACE_ID(UUID), HTH_PLUGINS_APPROVED(optional, comma list of approved plugin IDs), curl, jq
# =============================================================================
# HTH ChatGPT Dots Control 2.1: Restrict the app connections and actions dots
#   inherit to read-only by default
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls v8 3.3, 2.5; NIST 800-53 AC-3, AC-6, CM-7;
#   SOC 2 CC6.1, CC6.6; no benchmark equivalent yet
#
# Sources (fetched 2026-10-08):
#   https://chatgpt.com/public/admin/api-reference   (Admin API v2.5.37:
#     GET /compliance/workspaces/{workspace_id}/plugins              List Workspace Plugins
#     GET /compliance/workspaces/{workspace_id}/plugins/{plugin_id}  Get Workspace Plugin
#     security: chatgpt.enterprise.compliance_export read; limit 1-100 (default 50),
#     opaque cursor, has_more)
#   https://help.openai.com/en/articles/11509118
#   https://help.openai.com/en/articles/20001495-managing-app-permissions-in-chatgpt
#   https://help.openai.com/en/articles/20001529-dots-privacy-security-and-safety-faqs
#   https://learn.chatgpt.com/docs/enterprise/dots-admin-guide
#   https://learn.chatgpt.com/docs/enterprise/chatgpt-work-cloud-security
#   https://learn.chatgpt.com/docs/enterprise/apps-and-connectors  (Plugin controls:
#     Admin > Plugins > Public > Export CSV; fetched 2026-10-09)
#
# WHY AN INVENTORY AND NOT A CHECK. Dots act through the member's own app
# connections, and "Plugin permissions are shared across dots, ChatGPT, ChatGPT
# Work, and Codex" (help 20001529). The control is the per-app Action control
# and App permissions setting (help 11509118). No Admin API route reads or
# writes either one, so this pack cannot prove the read-only baseline. What it
# can do is list every live workspace-scoped plugin and flag any plugin that is
# not on your approved list. That is only half the set you walk in the console:
# the API excludes the global (public) catalog, including OpenAI-built plugins
# such as Gmail and Google Drive, and user-scoped plugins (TRAP 2).
#
# TRAPS
#  1. NO ACTION-CONTROL STATE. Neither endpoint carries Action control or App
#     permissions, and Get Workspace Plugin says "user-specific effective policy
#     overrides are not exposed". A clean run says nothing about whether write
#     actions are enabled. The only machine evidence of an Action-control change
#     is AUDIT_LOG APP_SET_ENABLED_ACTIONS (see the 2.01 Sigma rule).
#  2. TWO INVENTORIES, NEITHER COMPLETE. This API lists "all live
#     workspace-scoped plugins ... including private and unlisted plugins" and
#     excludes the global catalog and user-scoped plugins. Admin > Plugins >
#     Public > Export CSV is the opposite: the public catalog only, up to 48
#     hours old, without workspace-created plugins. Use both.
#  3. THE ONLY DOCUMENTED SCOPE IS THE BROAD LEGACY ONE. Both routes require
#     chatgpt.enterprise.compliance_export read, which in v2.5.37 authorizes 57
#     operations, including reading every Compliance Logs Platform type
#     (conversation content included). No narrower scope is documented for this
#     route. Mint a dedicated key, store it like a content-read credential, and
#     never grant compliance_export delete alongside it (the same path has a
#     DELETE that removes the plugin).
#  4. installation_policy, authentication_policy and status are free strings in
#     the spec with no enumerated values. They are printed as returned and not
#     interpreted.
#  5. PLAN. Role-specific app access and this API are Enterprise/Edu only.
#     Business enables apps by default and has no Admin API; Pro has only the
#     owner's Settings > Plugins > Permissions.
#  6. LABEL CONFLICT for the App permissions options echoed at the end.
#     Help 11509118 and help 20001495 list Always ask / Allow read actions /
#     Allow low-risk actions / Allow all actions; learn Work Cloud security
#     lists Always ask / Any changes / Important actions / Never ask. If the
#     learn labels appear, Always ask is unchanged and Any changes ("supported
#     reads can proceed without a prompt while changes require confirmation")
#     corresponds to Allow read actions, not to a read-only setting; never
#     choose Important actions or Never ask. Unresolved in a live tenant.
#
# Usage:
#   hth-chatgpt-dots-2.01-inventory-workspace-plugins.sh            # inventory
#   hth-chatgpt-dots-2.01-inventory-workspace-plugins.sh --detail   # + share principals
# Exit codes: 0 inventory printed (no unapproved plugin) | 1 unapproved plugin(s)
#   when HTH_PLUGINS_APPROVED is set | 2 precondition
# =============================================================================

set -euo pipefail
HTH_PACK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR source=common.sh
. "${HTH_PACK_DIR}/common.sh"

DETAIL=0
case "${1:-}" in
  "") ;;
  --detail) DETAIL=1 ;;
  *) echo "usage: $(basename "$0") [--detail]" >&2; exit 2 ;;
esac

cgpt_require
CGPT_SCOPE_HINT="chatgpt.enterprise.compliance_export read"

APPROVED_JSON="[]"
if [ -n "${HTH_PLUGINS_APPROVED:-}" ]; then
  APPROVED_JSON="$(printf '%s' "${HTH_PLUGINS_APPROVED}" \
    | jq -R -s -c '[split(",")[] | gsub("^\\s+|\\s+$"; "") | select(length > 0)] | unique')"
fi

# HTH Guide Excerpt: begin inventory-workspace-plugins
PLUGINS="${CGPT_TMPDIR}/plugins.jsonl"
cgpt_paginate_cursor "/compliance/workspaces/${CHATGPT_WORKSPACE_ID}/plugins" "${PLUGINS}"
TOTAL="$(wc -l < "${PLUGINS}" | tr -d ' ')"
echo "=== Live workspace-scoped plugins: ${TOTAL} (global catalog and user plugins excluded — TRAP 2) ==="
jq -r '"  \(.id)  \(.current_release.display_name // .name // "(unnamed)") v\(.current_release.version // "?")"
       + "  discoverability=\(.discoverability // "?")  status=\(.status // "?")"
       + "  installation_policy=\(.installation_policy // "?")  authentication_policy=\(.authentication_policy // "?")"
       + "  marketplace=\(.marketplace_name // "-")  creator=\(.creator_account_user_id // "-")"' "${PLUGINS}"

# Who can reach each plugin. A `workspace` principal means every member — and so
# every member's dot — can use it.
if [ "${DETAIL}" -eq 1 ]; then
  echo ""
  echo "=== Share principals ==="
  while IFS= read -r PID; do
    [ -n "${PID}" ] || continue
    cgpt_safe_id "${PID}" "plugin ID"
    cgpt_get_ok "/compliance/workspaces/${CHATGPT_WORKSPACE_ID}/plugins/${PID}"
    jq -r '"  \(.id): " + ([(.share_principals // [])[]
             | "\(.principal_type):\(.name // .principal_id)(\(.role))"] | if length == 0 then "(none listed)" else join(", ") end)
           + (if any((.share_principals // [])[]; .principal_type == "workspace")
              then "   <- REVIEW: shared with the whole workspace" else "" end)' "${CGPT_BODY}"
  done < <(jq -r '.id' "${PLUGINS}")
fi

UNAPPROVED=0
if [ "$(jq 'length' <<<"${APPROVED_JSON}")" -gt 0 ]; then
  echo ""
  echo "=== Drift against HTH_PLUGINS_APPROVED ==="
  while IFS=$'\t' read -r PID PNAME; do
    echo "  FINDING: plugin ${PID} (${PNAME}) is live in the workspace but not approved"
    UNAPPROVED=$((UNAPPROVED + 1))
  done < <(jq -r --argjson ok "${APPROVED_JSON}" '
      . as $p | select(($ok | any(.[]; . == $p.id)) | not)
      | [.id, (.current_release.display_name // .name // "(unnamed)")] | @tsv' "${PLUGINS}")
  [ "${UNAPPROVED}" -gt 0 ] || echo "  every live WORKSPACE-SCOPED plugin is approved (public catalog and user plugins not checked — TRAP 2)"
fi

echo ""
echo "NEXT (console — TRAP 1, TRAP 2): walk every plugin above AND every enabled public plugin. This API cannot list"
echo "  Admin > Plugins > Public (OpenAI-built Gmail, Google Drive, Outlook among them). For each app, open"
echo "  Admin > Plugins > {plugin} > Apps > {app}, or Workspace apps at https://chatgpt.com/admin/ca:"
echo "  Actions: enable only Read actions | New actions: Only enable new read actions or Disable new actions |"
echo "  Permissions: Always ask for apps holding sensitive data; Allow read actions only for low-sensitivity apps (TRAP 6)"
[ "${UNAPPROVED}" -eq 0 ] || exit 1
exit 0
# HTH Guide Excerpt: end inventory-workspace-plugins
