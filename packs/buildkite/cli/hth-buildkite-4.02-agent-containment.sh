#!/usr/bin/env bash
# =============================================================================
# HTH Buildkite Control 4.2: Contain a Compromised Build Fleet
#   — AGENT half (enumerate, pause dispatch, stop agents, restore)
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 17.4 | NIST 800-53 IR-4
# Source: https://howtoharden.com/guides/buildkite/#42-contain-a-compromised-build-fleet
#
# PAIRS WITH: packs/buildkite/terraform/hth-buildkite-4.02-containment.tf
#
# WHY THIS IS A cli/ PACK AND NOT terraform/.
# There is no `buildkite_agent` resource and no agent data source in
# buildkite/buildkite v1.38.0 — 21 resources and 16 data sources, none of them an
# agent. Terraform can pause a QUEUE and nothing else. Every agent verb lives in
# `bk` (which drives REST) and in GraphQL. A team whose whole operational muscle
# is `terraform apply` has no path to the controls that decide this incident.
#
# -----------------------------------------------------------------------------
# THE ORDER IS THE CONTROL — and the guide's Step 3 says why
# -----------------------------------------------------------------------------
#   1. PAUSE DISPATCH   stop new jobs being handed to the cluster's queues.
#   2. STOP AGENTS      terminate the processes actually holding the attacker's
#                       code. Forced only when you accept losing the running
#                       job's output — sometimes that output is the evidence.
#   3. REVOKE TOKENS    so nothing re-registers. LAST, never instead.
#
# REVOKING AN AGENT TOKEN DOES NOT DISCONNECT A CONNECTED AGENT. A responder who
# revokes tokens and stops there has blocked *registration* while every already-
# connected agent keeps executing jobs, keeps holding whatever secrets the job
# was given, and keeps producing log lines that overwrite the evidence. Token
# revocation is deliberately NOT implemented here — it belongs to controls 3.1
# and 2.5 — precisely so it cannot be mistaken for containment. This script
# refuses to pretend otherwise and prints the handoff at the end of `contain`.
#
# -----------------------------------------------------------------------------
# TRAPS — every one read from source, not from memory
# -----------------------------------------------------------------------------
# T1  `bk agent pause` AUTO-RESUMES, BY DEFAULT, AFTER 5 MINUTES.
#     cmd/agent/pause.go: `TimeoutInMinutes int ... default:"5"`, rejected unless
#     1 <= n <= 1440, and pauseOpts is populated on every invocation — the CLI
#     has no way to express "paused until I say otherwise". A responder who types
#     `bk agent pause <id>` and moves on gets the agent back five minutes later.
#     GraphQL agentPause's `timeoutInMinutes` is a nullable Int and CAN be
#     omitted, so the indefinite pause exists only on the GraphQL path. This
#     script uses GraphQL for pause and says so.
# T2  PAUSE IS NOT STOP. Vendor help text: a paused agent "will stop accepting
#     new jobs but will continue running any jobs it has already started." On a
#     compromised agent the job already started IS the compromise. Pause buys
#     time; only `stop --force` ends it.
# T3  TWO DIFFERENT IDENTIFIERS, AND THEY LOOK NOTHING ALIKE.
#     `bk` and REST take the agent UUID (`.id` in REST JSON). GraphQL
#     agentPause/agentResume/agentStop take `id: ID!`, the opaque base64 node id
#     (`.graphql_id` in REST JSON). Feeding a uuid to GraphQL fails; feeding a
#     node id to `bk` fails. `enumerate` below emits BOTH for every agent.
# T4  `bk agent stop` SILENTLY IGNORES POSITIONAL ARGS WHEN STDIN HAS DATA.
#     cmd/agent/stop.go checks `bkIO.HasDataAvailable(os.Stdin)` FIRST and only
#     falls back to `c.Agents` when stdin is empty. Inside a runbook whose stdin
#     is redirected from some other file, `bk agent stop $TARGETS` stops whatever
#     that file lists instead. Every `bk` invocation here is `< /dev/null`.
# T5  A BARE UUID USES `bk`'s CURRENTLY SELECTED ORGANIZATION.
#     The agent argument is "ORGANIZATION_SLUG/UUID" and "if the ORGANIZATION_SLUG/
#     portion is omitted, it uses the currently selected organization". Contain
#     the wrong org and you have caused the outage yourself. This script always
#     qualifies with "${BUILDKITE_ORG_SLUG}/".
# T6  `bk agent list` TRUNCATES AT 100 AND FILTERS CLIENT-SIDE.
#     `Limit int ... default:"100"`, `PerPage ... default:"30"`, and
#     filterAgents() is applied to each fetched page after the fact. A fleet
#     larger than the limit is silently cut off — during containment that is a
#     missed host. Enumeration here uses GraphQL with real pagination.
# T7  `bk agent list` HAS NO CLUSTER FILTER. Its options are name / hostname /
#     version / state / tags. Containment is cluster-scoped, so cluster targeting
#     must come from GraphQL, where Agent.clusterQueue.cluster.uuid is readable.
# T8  agentStop's `graceful: Boolean` IS THE INVERSE OF `bk agent stop --force`.
#     graceful=true lets the running job finish; --force "terminat[es] any jobs in
#     progress" (REST PUT .../agents/{id}/stop with {"force":true}). Choose
#     deliberately: forced stop contains faster and destroys the job output that
#     may be your only record of what ran.
# T9  PAUSING DISPATCH DOES NOT RECALL WORK ALREADY HANDED OUT. A queue with
#     dispatchPaused=true still has agents mid-job. Dispatch pause is step 1 of
#     three, never the whole answer.
#
# -----------------------------------------------------------------------------
# VERIFICATION STATUS
# -----------------------------------------------------------------------------
# GraphQL half — SCHEMA-VERIFIED LIVE, MUTATIONS NOT EXECUTED. Every mutation,
#   input field, nullability and payload selection below was introspected against
#   the live grcengineering GraphQL endpoint on 2026-08-18:
#     agentPause(input: AgentPauseInput{ clientMutationId, id: ID!, note,
#                timeoutInMinutes: Int }) -> AgentPausePayload{ agent, clientMutationId }
#     agentResume(input: AgentResumeInput{ clientMutationId, id: ID! })
#                -> AgentResumePayload{ agent, clientMutationId }
#     agentStop(input: AgentStopInput{ clientMutationId, id: ID!, graceful: Boolean })
#                -> AgentStopPayload{ agent, clientMutationId }
#     clusterQueuePauseDispatch(input: ClusterQueuePauseDispatchInput{
#                clientMutationId, id: ID!, note })
#                -> ClusterQueuePauseDispatchPayload{ queue, clientMutationId }
#     clusterQueueResumeDispatch(input: ClusterQueueResumeDispatchInput{
#                clientMutationId, id: ID! })
#                -> ClusterQueueResumeDispatchPayload{ queue, clientMutationId }
#   Agent fields (paused, pausedAt, pausedNote, pausedTimeoutInMinutes,
#   isRunningJob, connectionState, clusterQueue, stopForcedAt) and ClusterQueue
#   fields (dispatchPaused, dispatchPausedAt, dispatchPausedBy, dispatchPausedNote)
#   are all confirmed present.
#   Every mutation document below was then submitted to the LIVE endpoint with its
#   variables deliberately omitted, so the server answered in the VALIDATION phase
#   and no resolver ran. All five returned exactly one error — "Variable $id of
#   type ID! was provided invalid value" — and nothing else: no unknown field, no
#   unknown argument, no invalid selection. That is proof the documents are
#   correct AND proof nothing was executed. Stopping the principal's agents is not
#   a drill, so no mutation was ever sent with real variables.
# Enumeration half — VERIFIED-LIVE. Both read queries were executed in full
#   against the live organization on 2026-08-18. The queue query returned five
#   real queues with their GraphQL ids and dispatchPaused=false for each; the
#   agent query returned successfully with an empty fleet (this tenant runs no
#   agents), so the document is confirmed valid but the non-empty pagination path
#   is exercised only by the identical pattern in pack 2.5.
# `bk` half — DRIFT-CHECKED-ONLY. `bk` is not on PATH in the authoring
#   environment, so no `bk` command here was executed. Every subcommand, flag
#   spelling and default was read from buildkite/cli at main
#   (cmd/agent/{list,pause,resume,stop}.go) and cross-checked against
#   buildkite.com/docs/platform/cli/reference/agent, plus the REST paths those
#   commands call in buildkite/go-buildkite (PUT v2/organizations/{org}/agents/
#   {id}/{pause,resume,stop}).
#
# AGENT MAJOR VERSION: agent-side behaviour here is buildkite-agent **v3** (the
# current major; no v4 is released). Pause/stop are control-plane operations, so
# there is no v3/v4 divergence in this pack.
#
# Requires: BUILDKITE_TOKEN (GraphQL-enabled API access token), BUILDKITE_ORG_SLUG,
#           curl, jq. `bk` is OPTIONAL and used only to parallelise bulk stops.
# =============================================================================

set -euo pipefail

: "${BUILDKITE_TOKEN:?set BUILDKITE_TOKEN (GraphQL-enabled API access token)}"
: "${BUILDKITE_ORG_SLUG:?set BUILDKITE_ORG_SLUG (organization slug from your Buildkite URL)}"

GQL="https://graphql.buildkite.com/v1"
BK="${BK:-bk}"

gql() {
  curl -sS --fail-with-body -X POST "${GQL}" \
    -H "Authorization: Bearer ${BUILDKITE_TOKEN}" \
    -H "Content-Type: application/json" \
    --data @-
}

# Abort on a GraphQL-layer error. A containment step that "succeeded" because jq
# read a null out of an error response is the worst possible failure mode here.
die_on_gql_errors() {
  local body="$1"
  if jq -e '.errors' >/dev/null 2>&1 <<<"${body}"; then
    jq -r '"GraphQL error: " + ([.errors[].message] | join("; "))' <<<"${body}" >&2
    exit 1
  fi
}

# HTH Guide Excerpt: begin enumerate-fleet
# Everything containment needs, in one pass: which queues are already paused, and
# every agent in the cluster with BOTH identifiers (T3) plus whether it is
# currently executing a job (which decides pause-vs-force-stop, T2/T8).
#
# Paginated properly rather than through `bk agent list`, whose --limit defaults
# to 100 and whose filters run client-side (T6), and which cannot scope to a
# cluster at all (T7). Cluster scoping is done here on
# Agent.clusterQueue.cluster.uuid — a field, not a filter argument, so it is
# read and compared rather than guessed at.
fetch_queue_page() {
  local cluster_uuid="$1" after="$2"
  jq -n --arg slug "${BUILDKITE_ORG_SLUG}" --arg cu "${cluster_uuid}" --arg after "${after}" '{
    query: "query($slug:ID!,$cu:ID!,$after:String){ organization(slug:$slug){
              cluster(id:$cu){ uuid name
                queues(first:100, after:$after){
                  edges { node {
                    id uuid key
                    dispatchPaused dispatchPausedAt dispatchPausedNote
                    dispatchPausedBy { name email }
                  } }
                  pageInfo { hasNextPage endCursor }
                } } } }",
    variables: { slug: $slug, cu: $cu, after: (if $after == "" then null else $after end) }
  }' | gql
}

list_queues() {
  local cluster_uuid="${1:?usage: queues <cluster-uuid>}"
  local after="" page out="[]"
  while :; do
    page=$(fetch_queue_page "${cluster_uuid}" "${after}")
    die_on_gql_errors "${page}"
    out=$(jq -s 'add' \
      <(printf '%s' "${out}") \
      <(jq '[.data.organization.cluster.queues.edges[].node]' <<<"${page}"))
    [ "$(jq -r '.data.organization.cluster.queues.pageInfo.hasNextPage' <<<"${page}")" = "true" ] || break
    after=$(jq -r '.data.organization.cluster.queues.pageInfo.endCursor' <<<"${page}")
  done
  printf '%s\n' "${out}"
}

fetch_agent_page() {
  local after="$1"
  jq -n --arg slug "${BUILDKITE_ORG_SLUG}" --arg after "${after}" '{
    query: "query($slug:ID!,$after:String){ organization(slug:$slug){
              agents(first:100, after:$after){
                edges { node {
                  id uuid name hostname ipAddress version
                  connectionState isRunningJob
                  paused pausedAt pausedNote pausedTimeoutInMinutes
                  stopForcedAt stoppedGracefullyAt
                  clusterQueue { id key cluster { uuid name } }
                } }
                pageInfo { hasNextPage endCursor }
              } } }",
    variables: { slug: $slug, after: (if $after == "" then null else $after end) }
  }' | gql
}

# `id` here is the GraphQL node id (GraphQL mutations); `uuid` is what `bk` and
# REST want (T3). Both are emitted so no caller has to know which is which.
list_agents() {
  local cluster_uuid="${1:-}"
  local after="" page out="[]"
  while :; do
    page=$(fetch_agent_page "${after}")
    die_on_gql_errors "${page}"
    out=$(jq -s 'add' \
      <(printf '%s' "${out}") \
      <(jq '[.data.organization.agents.edges[].node]' <<<"${page}"))
    [ "$(jq -r '.data.organization.agents.pageInfo.hasNextPage' <<<"${page}")" = "true" ] || break
    after=$(jq -r '.data.organization.agents.pageInfo.endCursor' <<<"${page}")
  done
  if [ -n "${cluster_uuid}" ]; then
    jq --arg cu "${cluster_uuid}" '[.[] | select(.clusterQueue.cluster.uuid == $cu)]' <<<"${out}"
  else
    printf '%s\n' "${out}"
  fi
}

# Read-only situation report. Safe to run at any time and the first thing to run
# during a drill: it answers "is anything still contained" for queues Terraform
# does not manage, which the 4.2 Terraform pack structurally cannot see.
status() {
  local cluster_uuid="${1:?usage: status <cluster-uuid>}"
  local queues agents
  queues=$(list_queues "${cluster_uuid}")
  agents=$(list_agents "${cluster_uuid}")
  jq -n --argjson q "${queues}" --argjson a "${agents}" '{
    queues_paused:   [ $q[] | select(.dispatchPaused)   | {key, id, dispatchPausedAt, dispatchPausedNote} ],
    queues_dispatching: [ $q[] | select(.dispatchPaused | not) | .key ],
    agents_total:    ($a | length),
    agents_running_job: [ $a[] | select(.isRunningJob) | {name, uuid, graphql_id: .id, queue: .clusterQueue.key} ],
    agents_paused:   [ $a[] | select(.paused) | {name, uuid, graphql_id: .id, pausedNote, pausedTimeoutInMinutes} ],
    agents_connected: [ $a[] | select(.connectionState == "connected") | {name, uuid, graphql_id: .id} ]
  }'
}
# HTH Guide Excerpt: end enumerate-fleet

# HTH Guide Excerpt: begin contain-fleet
# STEP 1 — pause dispatch. Stops new jobs being handed out. Does not recall work
# already dispatched (T9), and does not touch a running job (T2).
pause_queue() {
  local queue_id="${1:?usage: pause-queue <queue-graphql-id> [note]}"
  local note="${2:-HTH 4.2 containment}"
  local body
  body=$(jq -n --arg id "${queue_id}" --arg note "${note}" '{
    query: "mutation($id:ID!,$note:String){ clusterQueuePauseDispatch(input:{id:$id, note:$note}){
              queue { id key dispatchPaused dispatchPausedAt dispatchPausedNote
                      dispatchPausedBy { name email } } } }",
    variables: { id: $id, note: $note }
  }' | gql)
  die_on_gql_errors "${body}"
  jq -r '.data.clusterQueuePauseDispatch.queue
         | "queue \(.key) dispatchPaused=\(.dispatchPaused) at \(.dispatchPausedAt // "-") by \(.dispatchPausedBy.name // "-")"' <<<"${body}"
}

# STEP 1b — pause agents. INDEFINITE, on purpose. `bk agent pause` cannot express
# this: its --timeout-in-minutes defaults to 5 and is always sent (T1). Omitting
# timeoutInMinutes here means the agent stays paused until someone resumes it.
# Still not containment on its own — a paused agent finishes its current job (T2).
pause_agent() {
  local agent_gql_id="${1:?usage: pause-agent <agent-graphql-id> [note]}"
  local note="${2:-HTH 4.2 containment — indefinite, no auto-resume}"
  local body
  body=$(jq -n --arg id "${agent_gql_id}" --arg note "${note}" '{
    query: "mutation($id:ID!,$note:String){ agentPause(input:{id:$id, note:$note}){
              agent { id uuid name paused pausedAt pausedNote
                      pausedTimeoutInMinutes isRunningJob } } }",
    variables: { id: $id, note: $note }
  }' | gql)
  die_on_gql_errors "${body}"
  jq -r '.data.agentPause.agent
         | "agent \(.name) paused=\(.paused) timeout=\(.pausedTimeoutInMinutes // "none (indefinite)") stillRunningJob=\(.isRunningJob)"' <<<"${body}"
}

# STEP 2 — stop agents. This is the step that ends execution.
#   graceful=true  -> the running job finishes. Evidence preserved, containment slower.
#   graceful=false -> equivalent to `bk agent stop --force`. Job terminated (T8).
stop_agent() {
  local agent_gql_id="${1:?usage: stop-agent <agent-graphql-id> [graceful|force]}"
  local mode="${2:-graceful}"
  local graceful
  case "${mode}" in
    graceful) graceful=true ;;
    force)    graceful=false ;;
    *) echo "FATAL: mode must be 'graceful' or 'force' (got '${mode}')." >&2; exit 2 ;;
  esac
  local body
  body=$(jq -n --arg id "${agent_gql_id}" --argjson g "${graceful}" '{
    query: "mutation($id:ID!,$g:Boolean){ agentStop(input:{id:$id, graceful:$g}){
              agent { id uuid name connectionState
                      stopForcedAt stoppedGracefullyAt } } }",
    variables: { id: $id, g: $g }
  }' | gql)
  die_on_gql_errors "${body}"
  jq -r '.data.agentStop.agent
         | "agent \(.name) state=\(.connectionState) forcedAt=\(.stopForcedAt // "-") gracefulAt=\(.stoppedGracefullyAt // "-")"' <<<"${body}"
}

# Bulk stop. `bk agent stop` parallelises (--limit, default 5 workers) so it is
# preferred when present; it takes the UUID, never the GraphQL id (T3), is always
# organization-qualified (T5), and is always given </dev/null so a redirected
# stdin cannot silently replace the target list (T4). Without `bk`, the same work
# runs serially over GraphQL — slower, identical outcome.
stop_agents_bulk() {
  local cluster_uuid="${1:?usage: stop-agents <cluster-uuid> [graceful|force]}"
  local mode="${2:-graceful}"
  local agents count
  agents=$(list_agents "${cluster_uuid}")
  count=$(jq 'length' <<<"${agents}")
  [ "${count}" -gt 0 ] || { echo "no agents in cluster ${cluster_uuid}; nothing to stop"; return 0; }
  echo "stopping ${count} agent(s) in cluster ${cluster_uuid} (mode=${mode})"

  if command -v "${BK}" >/dev/null 2>&1; then
    # Organization-qualified UUIDs (T5, T3), passed as POSITIONAL arguments with
    # stdin nailed to /dev/null. Piping them into xargs would not work: `bk` reads
    # stdin in preference to its arguments (T4), so redirecting xargs' stdin
    # discards the very list being piped. Build the argv instead.
    local -a targets=()
    while read -r qualified; do targets+=( "${qualified}" ); done \
      < <(jq -r --arg org "${BUILDKITE_ORG_SLUG}" '.[] | "\($org)/\(.uuid)"' <<<"${agents}")

    local -a bk_args=( agent stop --limit 5 )
    [ "${mode}" = "force" ] && bk_args+=( --force )
    "${BK}" "${bk_args[@]}" "${targets[@]}" < /dev/null
  else
    # No `bk`: same outcome serially over GraphQL, using the node id, not the uuid.
    while read -r gid; do stop_agent "${gid}" "${mode}"; done \
      < <(jq -r '.[].id' <<<"${agents}")
  fi
}

# The whole runbook, in the order that works. Deliberately stops one step short:
# token revocation is controls 3.1 / 2.5 and is printed as a handoff rather than
# performed, so nobody can mistake "this script finished" for "the fleet cannot
# re-register".
contain() {
  local cluster_uuid="${1:?usage: contain <cluster-uuid> [graceful|force]}"
  local mode="${2:-graceful}"

  echo "── step 1: pause dispatch on every queue in the cluster"
  while read -r qid; do pause_queue "${qid}" "HTH 4.2 containment"; done \
    < <(list_queues "${cluster_uuid}" | jq -r '.[] | select(.dispatchPaused | not) | .id')

  echo "── step 1b: pause agents indefinitely (no auto-resume)"
  while read -r aid; do pause_agent "${aid}"; done \
    < <(list_agents "${cluster_uuid}" | jq -r '.[] | select(.paused | not) | .id')

  echo "── step 2: stop agents (mode=${mode})"
  stop_agents_bulk "${cluster_uuid}" "${mode}"

  echo "── step 3: REVOKE TOKENS — NOT DONE BY THIS SCRIPT, AND NOT OPTIONAL"
  cat >&2 <<'HANDOFF'
Agents are stopped; nothing has been revoked. Revocation does not disconnect
connected agents, which is why it comes last — but skipping it means the cluster
registration token is still valid and a rebuilt-from-the-same-image host will
re-register straight back into the incident.

  cluster agent tokens : packs/buildkite/terraform/hth-buildkite-3.01-configure-agent-tokens.tf
                         (change rotation_id to force replacement), or GraphQL
                         clusterAgentTokenRevoke{ id: ID!, organizationId: ID! }
  org API tokens       : packs/buildkite/api/hth-buildkite-2.05-token-hygiene.sh revoke

Do not resume dispatch until fresh tokens are issued and the agent hosts are
REBUILT rather than restarted.
HANDOFF
}
# HTH Guide Excerpt: end contain-fleet

# HTH Guide Excerpt: begin restore-fleet
# Restore is the step that hands work back to a fleet that was contained for a
# reason, so it refuses to run on an assumption. HTH_HOSTS_REBUILT=1 is the
# operator asserting the agent hosts were rebuilt from a known-good image and
# fresh registration tokens were issued — the two things that make resuming
# something other than restarting the incident.
assert_restore_authorised() {
  [ "${HTH_HOSTS_REBUILT:-0}" = "1" ] || {
    cat >&2 <<'REFUSE'
REFUSING to resume dispatch.

Set HTH_HOSTS_REBUILT=1 only once BOTH are true:
  * the agent hosts were REBUILT from a known-good image, not restarted — a
    restarted host still carries whatever the compromised job wrote to it;
  * the cluster's agent registration tokens were rotated, so the old token
    cannot bring the old fleet back.

Resuming without these returns the compromised fleet to production with a
green checkmark next to it.
REFUSE
    exit 3
  }
}

resume_queue() {
  assert_restore_authorised
  local queue_id="${1:?usage: resume-queue <queue-graphql-id>}"
  local body
  body=$(jq -n --arg id "${queue_id}" '{
    query: "mutation($id:ID!){ clusterQueueResumeDispatch(input:{id:$id}){
              queue { id key dispatchPaused } } }",
    variables: { id: $id }
  }' | gql)
  die_on_gql_errors "${body}"
  jq -r '.data.clusterQueueResumeDispatch.queue
         | "queue \(.key) dispatchPaused=\(.dispatchPaused)"' <<<"${body}"
}

resume_agent() {
  assert_restore_authorised
  local agent_gql_id="${1:?usage: resume-agent <agent-graphql-id>}"
  local body
  body=$(jq -n --arg id "${agent_gql_id}" '{
    query: "mutation($id:ID!){ agentResume(input:{id:$id}){
              agent { id uuid name paused connectionState } } }",
    variables: { id: $id }
  }' | gql)
  die_on_gql_errors "${body}"
  jq -r '.data.agentResume.agent
         | "agent \(.name) paused=\(.paused) state=\(.connectionState)"' <<<"${body}"
}

restore() {
  assert_restore_authorised
  local cluster_uuid="${1:?usage: restore <cluster-uuid>}"
  echo "── resuming paused agents"
  while read -r aid; do resume_agent "${aid}"; done \
    < <(list_agents "${cluster_uuid}" | jq -r '.[] | select(.paused) | .id')
  echo "── resuming queue dispatch"
  while read -r qid; do resume_queue "${qid}"; done \
    < <(list_queues "${cluster_uuid}" | jq -r '.[] | select(.dispatchPaused) | .id')
  echo "── post-restore state"
  status "${cluster_uuid}"
}
# HTH Guide Excerpt: end restore-fleet

case "${1:-help}" in
  status)        status "${2:-}" ;;
  queues)        list_queues "${2:-}" ;;
  agents)        list_agents "${2:-}" ;;
  pause-queue)   pause_queue "${2:-}" "${3:-HTH 4.2 containment}" ;;
  pause-agent)   pause_agent "${2:-}" "${3:-HTH 4.2 containment — indefinite, no auto-resume}" ;;
  stop-agent)    stop_agent "${2:-}" "${3:-graceful}" ;;
  stop-agents)   stop_agents_bulk "${2:-}" "${3:-graceful}" ;;
  contain)       contain "${2:-}" "${3:-graceful}" ;;
  resume-queue)  resume_queue "${2:-}" ;;
  resume-agent)  resume_agent "${2:-}" ;;
  restore)       restore "${2:-}" ;;
  help|*)
    cat >&2 <<'USAGE'
usage: hth-buildkite-4.02-agent-containment.sh <verb> [args]

  read-only
    status <cluster-uuid>              what is paused, what is running a job
    queues <cluster-uuid>              queues + dispatch state (JSON)
    agents [cluster-uuid]              agents with BOTH ids: .uuid for bk/REST,
                                       .id for GraphQL

  contain (order matters)
    pause-queue  <queue-graphql-id> [note]      step 1  stop new dispatch
    pause-agent  <agent-graphql-id> [note]      step 1b indefinite, no auto-resume
    stop-agent   <agent-graphql-id> graceful|force
    stop-agents  <cluster-uuid>      graceful|force   step 2 bulk
    contain      <cluster-uuid>      graceful|force   steps 1 -> 1b -> 2

  restore (requires HTH_HOSTS_REBUILT=1)
    resume-queue <queue-graphql-id>
    resume-agent <agent-graphql-id>
    restore      <cluster-uuid>

`force` terminates jobs in progress. Sometimes that output is the evidence.
Token revocation is NOT part of this script — see controls 3.1 and 2.5. Revoking
a token does not disconnect a connected agent, so revocation alone is not
containment, and containment alone does not stop re-registration.
USAGE
    exit 2 ;;
esac
