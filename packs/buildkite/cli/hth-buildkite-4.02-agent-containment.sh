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
#     That part is VERIFIED, from source.
# T1b OMITTING timeoutInMinutes IS LEGAL. WHETHER IT MEANS "FOREVER" IS NOT
#     VERIFIED, AND THIS PACK NO LONGER ASSUMES IT.
#     `AgentPauseInput.timeoutInMinutes` is a nullable `Int` in the live schema,
#     so the GraphQL path CAN omit it where `bk` cannot. What no source here
#     establishes is what the server DOES with the omission: "no auto-resume" and
#     "apply the same default `bk` sends" are both consistent with a nullable
#     input, and the mutations in this pack have never been executed against a
#     live agent (see VERIFICATION STATUS). Two facts make a wrong assumption
#     invisible rather than loud:
#       * `Agent.pausedTimeoutInMinutes` is `Int!` — NON_NULL in the live schema.
#         The server therefore always reports a number, so a `// "indefinite"`
#         jq fallback can never fire and a server-applied 5 would print as an
#         ordinary field under a header promising no auto-resume.
#       * containment that releases itself does so silently, minutes after the
#         responder has read the handoff and moved on.
#     So `pause_agent` ASSERTS on the value the server returns and fails loudly
#     on any non-zero timeout instead of trusting the omission. Treat "indefinite
#     pause" as an unverified assumption that the tool checks, not a guarantee —
#     and note that pause is never the containment step regardless (T2): `stop`
#     is. Executing agentPause against a real agent and recording what
#     pausedTimeoutInMinutes comes back as is the one thing that would settle it.
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
# T7b CLUSTER-SCOPED CONTAINMENT CANNOT REACH AN AGENT WITH NO CLUSTER.
#     `Agent.clusterQueue` is `ClusterQueue` — OBJECT, not NON_NULL — and
#     `ClusterQueue.cluster` is nullable too, so an agent can legitimately have
#     no resolvable cluster uuid. Legacy UNCLUSTERED agents are the obvious case
#     (organizations created before 2024-02-26 can still have them; see
#     terraform/hth-buildkite-3.03-secure-agent-infrastructure.tf). Filtering on
#     `.clusterQueue.cluster.uuid == $cu` silently DROPS every one of them, and a
#     total counted after that filter hides the omission: the responder reads a
#     fleet size that already excludes the agents nobody told them about, and
#     `contain` leaves those agents running. Every read path here therefore
#     reports an explicit `agents_unassociated` bucket alongside the in-cluster
#     count, `contain` prints a loud warning naming them, and both `status` and
#     `agents` show the organization-wide total next to the scoped one.
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
#   are all confirmed present. Two nullabilities from that same introspection
#   drive real behaviour here and are worth restating: Agent.clusterQueue is
#   NULLABLE (T7b) and Agent.pausedTimeoutInMinutes is NON_NULL (T1b).
#   WHAT IS NOT VERIFIED: the server-side MEANING of omitting
#   AgentPauseInput.timeoutInMinutes. Schema introspection proves the omission is
#   accepted; it cannot prove the resulting pause never expires. That claim is
#   asserted at runtime rather than assumed (T1b) and is the top item to settle
#   the next time this pack is exercised against a live agent.
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

# Every agent in the ORGANIZATION, unfiltered. `id` here is the GraphQL node id
# (GraphQL mutations); `uuid` is what `bk` and REST want (T3). Both are emitted
# so no caller has to know which is which.
list_all_agents() {
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
  printf '%s\n' "${out}"
}

# Agents whose cluster uuid cannot be resolved AT ALL — clusterQueue is null, or
# it is present but its cluster is (both are nullable, T7b). These are the agents
# cluster-scoped containment structurally cannot reach. Kept as its own function
# so the omission has a name and can be printed, rather than being an invisible
# consequence of a `select`.
select_unassociated_agents() {
  jq '[.[] | select((.clusterQueue.cluster.uuid // null) == null)]'
}

select_cluster_agents() {
  jq --arg cu "${1}" '[.[] | select(.clusterQueue.cluster.uuid == $cu)]'
}

# Cluster-scoped view. WARNS on stderr about anything the scope cannot reach
# (T7b) so a caller that only reads stdout still cannot be misled about totals.
list_agents() {
  local cluster_uuid="${1:-}"
  local all unassoc n_unassoc
  all=$(list_all_agents)
  [ -n "${cluster_uuid}" ] || { printf '%s\n' "${all}"; return 0; }

  unassoc=$(select_unassociated_agents <<<"${all}")
  n_unassoc=$(jq 'length' <<<"${unassoc}")
  [ "${n_unassoc}" -eq 0 ] || echo "WARNING: ${n_unassoc} agent(s) have no resolvable cluster and are NOT in this list; cluster-scoped containment does not reach them (T7b). See: status ${cluster_uuid} | jq .agents_unassociated" >&2
  select_cluster_agents "${cluster_uuid}" <<<"${all}"
}

# Read-only situation report. Safe to run at any time and the first thing to run
# during a drill: it answers "is anything still contained" for queues Terraform
# does not manage, which the 4.2 Terraform pack structurally cannot see.
#
# The counts are deliberately THREE numbers, not one. `agents_total` used to be
# reported after the cluster filter, so an agent the filter had dropped (T7b) was
# missing from the list AND from the total that was supposed to reveal the gap.
# Reconciliation is now explicit: agents_in_cluster + agents_unassociated +
# (agents in other clusters) = agents_org_total.
status() {
  local cluster_uuid="${1:?usage: status <cluster-uuid>}"
  local queues all
  queues=$(list_queues "${cluster_uuid}")
  all=$(list_all_agents)
  jq -n --arg cu "${cluster_uuid}" --argjson q "${queues}" --argjson all "${all}" '
    ($all | map(select(.clusterQueue.cluster.uuid == $cu)))          as $a |
    ($all | map(select((.clusterQueue.cluster.uuid // null) == null))) as $u |
    {
      queues_paused:      [ $q[] | select(.dispatchPaused)       | {key, id, dispatchPausedAt, dispatchPausedNote} ],
      queues_dispatching: [ $q[] | select(.dispatchPaused | not) | .key ],
      agents_in_cluster:  ($a   | length),
      agents_org_total:   ($all | length),
      agents_running_job: [ $a[] | select(.isRunningJob) | {name, uuid, graphql_id: .id, queue: .clusterQueue.key} ],
      agents_paused:      [ $a[] | select(.paused) | {name, uuid, graphql_id: .id, pausedNote, pausedTimeoutInMinutes} ],
      agents_connected:   [ $a[] | select(.connectionState == "connected") | {name, uuid, graphql_id: .id} ],
      agents_unassociated_count: ($u | length),
      agents_unassociated: [ $u[] | {name, uuid, graphql_id: .id, connectionState, isRunningJob} ],
      agents_unassociated_note:
        "Agents with no resolvable cluster (Agent.clusterQueue or ClusterQueue.cluster is null — legacy unclustered agents). Cluster-scoped containment does not reach them: `contain <cluster-uuid>` will NOT pause or stop these. Contain each directly with stop-agent <graphql_id> graceful|force."
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

# STEP 1b — pause agents. `timeoutInMinutes` is OMITTED, which `bk agent pause`
# cannot do (its --timeout-in-minutes defaults to 5 and is always sent, T1).
# The INTENT is a pause with no auto-resume. That intent is not verified (T1b),
# so it is checked rather than announced: Agent.pausedTimeoutInMinutes is NON_NULL
# in the schema, so the server always tells us what it actually applied, and a
# non-zero answer means containment has a clock on it and the responder must be
# told before they walk away. Pause is not containment on its own regardless —
# a paused agent finishes its current job (T2); `stop` is the step that ends it.
#
# Returns 4 when the pause carries an auto-resume, so a caller can count the
# agents that need re-pausing or stopping instead of trusting a green run.
assert_pause_has_no_auto_resume() {
  local body="$1" name gid timeout
  name=$(jq -r '.data.agentPause.agent.name // "<unknown>"' <<<"${body}")
  gid=$(jq -r '.data.agentPause.agent.id // "<agent-graphql-id>"' <<<"${body}")
  timeout=$(jq -r '.data.agentPause.agent.pausedTimeoutInMinutes // "unreported"' <<<"${body}")
  [ "${timeout}" = "0" ] && return 0
  cat >&2 <<EOF
WARNING: agent ${name} is paused WITH AN AUTO-RESUME of ${timeout} minute(s).
  This pack omits timeoutInMinutes intending an indefinite pause, but the server
  reported a non-zero timeout — so this agent WILL start accepting jobs again on
  its own, without anyone deciding that it should.
  Do not treat this agent as contained. Either re-pause it before the clock
  expires, or (correctly) stop it:
      stop-agent ${gid} graceful|force
EOF
  return 4
}

pause_agent() {
  local agent_gql_id="${1:?usage: pause-agent <agent-graphql-id> [note]}"
  local note="${2:-HTH 4.2 containment — no auto-resume intended, verify timeout below}"
  local body
  body=$(jq -n --arg id "${agent_gql_id}" --arg note "${note}" '{
    query: "mutation($id:ID!,$note:String){ agentPause(input:{id:$id, note:$note}){
              agent { id uuid name paused pausedAt pausedNote
                      pausedTimeoutInMinutes isRunningJob } } }",
    variables: { id: $id, note: $note }
  }' | gql)
  die_on_gql_errors "${body}"
  # No `// "indefinite"` fallback here: pausedTimeoutInMinutes is NON_NULL, so a
  # jq alternative operator on it is dead code that would print a reassurance the
  # server never sent. Print the number the server actually returned.
  jq -r '.data.agentPause.agent
         | "agent \(.name) paused=\(.paused) pausedTimeoutInMinutes=\(.pausedTimeoutInMinutes) stillRunningJob=\(.isRunningJob)"' <<<"${body}"
  assert_pause_has_no_auto_resume "${body}"
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
  local all unassoc n_unassoc aid
  local -a auto_resumed=()

  # STEP 0 — say what this run structurally cannot reach BEFORE doing anything,
  # so it is at the top of the responder's scrollback rather than buried (T7b).
  all=$(list_all_agents)
  unassoc=$(select_unassociated_agents <<<"${all}")
  n_unassoc=$(jq 'length' <<<"${unassoc}")
  echo "── step 0: scope — $(jq 'length' <<<"${all}") agent(s) in the organization, $(select_cluster_agents "${cluster_uuid}" <<<"${all}" | jq 'length') in this cluster"
  if [ "${n_unassoc}" -gt 0 ]; then
    {
      echo "!! ${n_unassoc} AGENT(S) ARE OUT OF SCOPE FOR THIS CONTAINMENT."
      echo "   They have no resolvable cluster (Agent.clusterQueue / ClusterQueue.cluster"
      echo "   is null — legacy unclustered agents look like this). Nothing below pauses or"
      echo "   stops them; they keep taking jobs while this runbook reports success."
      jq -r '.[] | "   OUT OF SCOPE: \(.name) graphql_id=\(.id) uuid=\(.uuid) state=\(.connectionState) runningJob=\(.isRunningJob)"' <<<"${unassoc}"
      echo "   Contain each directly:  stop-agent <graphql_id> ${mode}"
    } >&2
  fi

  echo "── step 1: pause dispatch on every queue in the cluster"
  while read -r qid; do pause_queue "${qid}" "HTH 4.2 containment"; done \
    < <(list_queues "${cluster_uuid}" | jq -r '.[] | select(.dispatchPaused | not) | .id')

  echo "── step 1b: pause agents (timeoutInMinutes omitted; the reported timeout is asserted)"
  # A pause that came back with an auto-resume clock must NOT abort the run:
  # step 2 is the step that actually contains, and aborting before it would leave
  # the fleet running. Collect the failures and surface them at the end instead.
  while read -r aid; do
    pause_agent "${aid}" || auto_resumed+=( "${aid}" )
  done < <(select_cluster_agents "${cluster_uuid}" <<<"${all}" | jq -r '.[] | select(.paused | not) | .id')

  echo "── step 2: stop agents (mode=${mode})"
  stop_agents_bulk "${cluster_uuid}" "${mode}"

  if [ "${#auto_resumed[@]}" -gt 0 ]; then
    {
      echo "!! ${#auto_resumed[@]} agent(s) were paused WITH AN AUTO-RESUME CLOCK (see warnings above):"
      printf '   %s\n' "${auto_resumed[@]}"
      echo "   The indefinite-pause assumption did not hold on this tenant. Verify each was"
      echo "   stopped by step 2, and correct T1b in this pack's header with what you saw."
    } >&2
  fi

  echo "── step 3: REVOKE TOKENS — NOT DONE BY THIS SCRIPT, AND NOT OPTIONAL"
  cat >&2 <<'HANDOFF'
Agents are stopped; nothing has been revoked. Revocation does not disconnect
connected agents, which is why it comes last — but skipping it means the cluster
registration token is still valid and a rebuilt-from-the-same-image host will
re-register straight back into the incident.

  cluster agent tokens : GraphQL clusterAgentTokenRevoke{ id: ID!, organizationId: ID! },
                         or packs/buildkite/api/hth-buildkite-3.01-agent-token-lifecycle.sh
                         (`revoke <token_id>`, or `contain <cluster_graphql_id> <token_id>`
                         which revokes AND stops the agents the token registered).
                         Terraform: DELETE the token's entry from var.agent_tokens in
                         hth-buildkite-3.01-configure-agent-tokens.tf and apply — the plan
                         reads "1 to destroy". Do NOT reach for a rotation here: rotation in
                         that pack is deliberately a two-apply add-then-remove (its TRAP 5),
                         because the new secret is returned exactly once and revoking the
                         incumbent in the same apply strands every host that has not yet
                         re-registered. During an incident you WANT the revoke; issue the
                         replacement token as a separate, later act.
  org API tokens       : packs/buildkite/api/hth-buildkite-2.05-token-hygiene.sh revoke

Do not resume dispatch until fresh tokens are issued and the agent hosts are
REBUILT rather than restarted.
HANDOFF

  # A run that could not reach every agent, or that paused agents onto an
  # auto-resume clock, must not exit 0 into a runbook that treats 0 as "the
  # fleet is contained".
  if [ "${n_unassoc}" -gt 0 ] || [ "${#auto_resumed[@]}" -gt 0 ]; then
    echo "CONTAINMENT INCOMPLETE: ${n_unassoc} agent(s) out of cluster scope, ${#auto_resumed[@]} agent(s) paused with an auto-resume clock. Exit 5." >&2
    return 5
  fi
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
  pause-agent)   pause_agent "${2:-}" "${3:-HTH 4.2 containment — no auto-resume intended, verify timeout below}" ;;
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
    status <cluster-uuid>              what is paused, what is running a job,
                                       plus agents_unassociated: the agents this
                                       cluster scope CANNOT reach (T7b)
    queues <cluster-uuid>              queues + dispatch state (JSON)
    agents [cluster-uuid]              agents with BOTH ids: .uuid for bk/REST,
                                       .id for GraphQL. With a cluster-uuid this
                                       is FILTERED — anything with no resolvable
                                       cluster is omitted and warned about on
                                       stderr. Omit the argument for every agent.

  contain (order matters)
    pause-queue  <queue-graphql-id> [note]      step 1  stop new dispatch
    pause-agent  <agent-graphql-id> [note]      step 1b timeoutInMinutes omitted;
                                                exits 4 if the server came back
                                                with an auto-resume clock anyway
    stop-agent   <agent-graphql-id> graceful|force
    stop-agents  <cluster-uuid>      graceful|force   step 2 bulk
    contain      <cluster-uuid>      graceful|force   steps 0 -> 1 -> 1b -> 2
                                                exits 5 if any agent was out of
                                                cluster scope or came back paused
                                                with an auto-resume clock

  restore (requires HTH_HOSTS_REBUILT=1)
    resume-queue <queue-graphql-id>
    resume-agent <agent-graphql-id>
    restore      <cluster-uuid>

`force` terminates jobs in progress. Sometimes that output is the evidence.

PAUSE IS AN UNVERIFIED INDEFINITE (T1b). This script omits timeoutInMinutes,
which is legal, but no source establishes that the server reads the omission as
"never auto-resume" — and `bk`'s own default is 5 minutes. Agent.pausedTimeout-
InMinutes is NON_NULL, so the server always reports what it applied; every pause
here asserts on it and fails loudly rather than promising you something.

CLUSTER SCOPE IS NOT THE WHOLE FLEET (T7b). Agent.clusterQueue is nullable, so a
legacy unclustered agent has no cluster uuid and no cluster-scoped verb touches
it. `status` counts it in agents_unassociated and `contain` names it at step 0.

Token revocation is NOT part of this script — see controls 3.1 and 2.5. Revoking
a token does not disconnect a connected agent, so revocation alone is not
containment, and containment alone does not stop re-registration.
USAGE
    exit 2 ;;
esac
