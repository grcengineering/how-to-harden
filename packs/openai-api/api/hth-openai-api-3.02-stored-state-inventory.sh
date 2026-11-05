#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: openai-api-3.2
#   guide: https://howtoharden.com/guides/openai-api/#32-bound-application-state-and-offboard-every-copy
#   profile: L1
#   mode: read-only
#   requires: OPENAI_API_KEY(project Files and Vector Stores read permissions), curl, jq
# Sources: https://developers.openai.com/api/reference/resources/files/methods/list
# https://developers.openai.com/api/reference/resources/vector_stores/methods/list
# NIST 800-53 SI-12. This inventories two state stores, not every API object.
source "$(dirname "$0")/common.sh"
: "${OPENAI_API_KEY:?Inject a project workload key with read access}"
# Prevent an unrelated admin key from selecting the wrong API audience.
unset OPENAI_ADMIN_KEY
# HTH Guide Excerpt: begin stored-state-inventory
umask 077
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
trap 'exit 1' HUP INT TERM
openai_list '/files' | jq -c '{store:"files", id, purpose, created_at, expires_at}' > "$work/rows"
openai_list '/vector_stores' | jq -c '{store:"vector_stores", id, created_at, expires_after, expires_at}' >> "$work/rows"
cat "$work/rows"
# Delete/expire approved objects only after validating consumer dependencies.
# Review Agents sessions, Conversations, ChatKit, traces, model artifacts and
# external MCP copies separately; they have different lifecycle boundaries.
# HTH Guide Excerpt: end stored-state-inventory
