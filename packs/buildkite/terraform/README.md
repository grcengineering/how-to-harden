# Buildkite Hardening Code Pack - Terraform

Infrastructure-as-code implementation of the [Buildkite Hardening Guide](https://howtoharden.com/guides/buildkite/) from [How to Harden](https://howtoharden.com).

## Read this before you run anything

**Do not `terraform apply` this directory as a whole.** It is a catalogue of independent control implementations, not a deployable root module. Applying all of it at once does at least three things you did not ask for:

1. **`hth-buildkite-1.02` and `hth-buildkite-4.01` both declare `buildkite_organization`** against the one remote organization object. Two Terraform resources managing one object produces perpetual drift — each plan tries to reconcile the other's fields, and `allowed_api_ip_addresses` is `optional` but **not computed**, so the resource that omits it asserts null and the two fight over your API IP allowlist on alternating applies. **Adopt one of these two files, never both** (both files carry this warning in their own headers).
2. **`hth-buildkite-4.02-containment.tf` creates cluster queues; it does not adopt yours.** Its TRAP 3 is explicit: *"THIS RESOURCE CREATES. IMPORT FIRST OR YOU FIGHT YOURSELF."* Import every existing queue before the first apply — the import id is the pair `"<queue GraphQL id>,<cluster uuid>"`. See the `import` block in that file's header.
3. **Several controls are Enterprise-plan features** (pipeline templates, portals, registries, the API IP allowlist). `terraform validate` and `terraform plan` both pass without them; the failure appears only at apply, as a plan-upgrade error from the API.

Adopt **one control at a time**: copy the single `hth-buildkite-<control>.tf` you want, plus `providers.tf` and `variables.tf`, into your own Terraform root, and populate only that control's variables.

```bash
mkdir -p buildkite-hardening && cd buildkite-hardening

# providers + variables are shared scaffolding
cp .../packs/buildkite/terraform/{providers.tf,variables.tf} .
cp .../packs/buildkite/terraform/terraform.tfvars.example terraform.tfvars

# then ONE control file, e.g. team permissions
cp .../packs/buildkite/terraform/hth-buildkite-2.01-configure-team-permissions.tf .

# edit terraform.tfvars, then
terraform init
terraform plan      # read the plan; nothing here is safe to -auto-approve
terraform apply
```

**Do not copy `outputs.tf` wholesale.** It is written for the whole directory and references resources from six different control files, so a single-control root fails `terraform validate` with `Reference to undeclared resource`. Copy only the `output` blocks whose resources you actually adopted.

Two files depend on another control file's resources — adopt them together:

- `hth-buildkite-2.02` references `buildkite_team.teams`, which is declared in `hth-buildkite-2.01`.
- `outputs.tf`'s `enforce_2fa_enabled` references `buildkite_organization.hardened`, which is declared in `hth-buildkite-1.02` (and *not* by `4.01`, which declares `buildkite_organization.api_restrictions`).

`terraform.tfvars.example` ships with every resource-creating map either empty or commented out — with one exception, `teams`, which carries a worked three-team least-privilege example. Review it before applying `2.01`; everything else creates nothing until you write down what you want.

## Profile levels are a label, not a switch

| Level | Name | Description |
|-------|------|-------------|
| L1 | Crawl | 2FA enforcement, teams, agent tokens, secrets, portals, audit logging |
| L2 | Walk | Adds clusters, pipeline permissions, cluster maintainers, org rules, containment queues |
| L3 | Run | Adds pipeline templates, inbound OIDC trust policies, API IP restrictions |

Set via `terraform apply -var="profile_level=2"`, or in `terraform.tfvars`.

**`profile_level` does not create or destroy resources.** Each control is switched on by its own declaration map being non-empty (`var.clusters`, `var.pipelines`, `var.pipeline_templates`, …) and off by that map being empty. Every one of those maps defaults to `{}` except `var.teams`, which ships a three-team least-privilege example — so `buildkite_team` is the only resource in this directory that a bare apply creates without you having declared anything. Override or empty it if that is not what you want.

This used to be different, and it was dangerous. Packs 2.2, 3.2 and 3.10 gated their `for_each` on `var.profile_level >= N`. `profile_level` defaults to `1`, so an apply that forgot `-var="profile_level=3"` emptied the `for_each` map and **Terraform planned a destroy of every pipeline, cluster and template the pack had created** — taking build history, webhook URLs, cluster queues and cluster-scoped agent tokens with them. The `check` block that was supposed to make this visible could not: Terraform `check` blocks emit **warnings only**; they never fail a plan or halt an apply, and under `-auto-approve` the warning scrolls past a completed destroy. Those gates are gone.

Two consequences to know about:

- **`buildkite_pipeline` (packs 2.2 and 3.10), `buildkite_cluster` (pack 3.2), `buildkite_registry` (pack 3.11) and `buildkite_portal` (pack 2.5) carry `lifecycle { prevent_destroy = true }`.** Removing an entry from the corresponding map — or renaming a map key, which renames the object — now **fails the plan** instead of deleting the object. That is the point: a pipeline's build history and webhook URL do not come back, and a cluster destroy takes its queues and its cluster-scoped agent tokens with it (those token secrets are returned by the create call exactly once and are not recoverable from state). To retire one deliberately, delete the `prevent_destroy` line, apply, then restore it. It also means `terraform destroy` on a root holding these will refuse until you do the same.
- **`hth-buildkite-4.01` is the one file still gated on `profile_level`** (`count = var.profile_level >= 3 && length(var.allowed_api_ip_addresses) > 0`). That gate is kept on purpose: there it withholds a lockout-capable setting rather than destroying anything. Note the flip side — lowering `profile_level` below 3 with a populated `allowed_api_ip_addresses` **removes** the API IP restriction on the next apply. That is a silent control regression, not a data loss, but it is still a reason not to change the level casually.

## Prerequisites

- **OpenTofu / Terraform >= 1.5**, which is what `providers.tf` declares. Nine files here use `check` blocks — `2.03`, `2.05`, `2.07`, `3.01`, `3.05`, `3.07`, `3.10`, `3.11`, `4.02` — and on a 1.4.x CLI those do not parse.
- **>= 1.11 if you adopt `hth-buildkite-3.05-cluster-secrets.tf`**, which uses write-only arguments (`value_wo`). OpenTofu: a release with write-only attribute support. `providers.tf` does **not** declare this floor, deliberately — adopting one pack should not raise the toolchain floor for every other control — so raise `required_version` yourself in the root that holds `3.05`.
- Verified against **OpenTofu v1.12.5**: `tofu validate` on the whole directory returns `Success!` and `tofu fmt -check` is clean.
- Buildkite provider `~> 1.0`. Every attribute in these files was verified against the provider schema at **v1.38.0** (`tofu providers schema -json`).
- Buildkite plan: Enterprise or Business for SSO, teams, clusters, templates, portals, registries and the API IP allowlist. Individual files name their own plan requirement.
- Buildkite API token with GraphQL access and the `write_pipelines` / `read_pipelines` REST scopes.
- SAML IdP configured out of band (control 1.1 has no Terraform surface).

## Provider

| Name | Source | Version |
|------|--------|---------|
| buildkite | [buildkite/buildkite](https://registry.terraform.io/providers/buildkite/buildkite/latest) | `~> 1.0` (schema-verified against v1.38.0) |

## Controls Implemented

| File | Control | Profile | Notes |
|------|---------|---------|-------|
| `hth-buildkite-1.02-enforce-two-factor-authentication.tf` | 1.2 Enforce 2FA | L1 | **Singleton conflict with 4.01** — adopt one |
| `hth-buildkite-2.01-configure-team-permissions.tf` | 2.1 Team Permissions | L1 | All five `members_can_*` are optional+computed; set every one explicitly |
| `hth-buildkite-2.02-configure-pipeline-permissions.tf` | 2.2 Pipeline Permissions | L2 | `prevent_destroy` on pipelines |
| `hth-buildkite-2.03-limit-admin-access.tf` | 2.3 Limit Admin Access | L1 | Verification pack. Enforces **team-scoped** roles via `buildkite_team_member`; org-level admin is not grantable or revocable from the provider, and the members data source does not even return the org role — use the GraphQL census in the API pack |
| `hth-buildkite-2.05-portals.tf` | 2.5 API Token Hygiene (Portals) | L1 | |
| `hth-buildkite-2.07-organization-rules.tf` | 2.7 Cross-Pipeline Access Rules | L2 | |
| `hth-buildkite-3.01-configure-agent-tokens.tf` | 3.1 Agent Tokens | L1 | Token value is returned **once**. Rotation is a deliberate **two-apply** add-then-remove with the agent-host roll in between — never a single-apply replacement (see its TRAP 5) |
| `hth-buildkite-3.02-configure-agent-clusters.tf` | 3.2 Agent Clusters | L2 | `prevent_destroy` on clusters |
| `hth-buildkite-3.03-secure-agent-infrastructure.tf` | 3.3 Agent Infrastructure | L2 | `allowed_ip_addresses` is **lockout-capable** — a wrong CIDR strands every agent |
| `hth-buildkite-3.05-cluster-secrets.tf` | 3.5 Build Secrets | L1 | **Needs Terraform >= 1.11** (`value_wo`) |
| `hth-buildkite-3.07-cluster-maintainers.tf` | 3.7 Delegate Cluster Admin | L2 | Takes cluster `uuid`, not the GraphQL `id` |
| `hth-buildkite-3.10-pipeline-templates.tf` | 3.10 Pipeline Templates | L3 | `prevent_destroy` on templated pipelines; Enterprise feature |
| `hth-buildkite-3.11-inbound-oidc.tf` | 3.11 Inbound OIDC Trust | L3 | `prevent_destroy` on registries |
| `hth-buildkite-4.01-configure-audit-logging.tf` | 4.1 Audit Logging / API IP allowlist | L1 / L3 | **Singleton conflict with 1.02** — adopt one. Self-sealing lockout risk |
| `hth-buildkite-4.02-containment.tf` | 4.2 Contain a Compromised Fleet | L2 | **Import existing queues first** — this file creates, it does not adopt |

Control **1.1 (SAML SSO)** has no Terraform resource in provider `~> 1.0`; use the guide's ClickOps path or the API pack. There is likewise no Terraform resource for the organization-level "require pipeline templates" strictness (pack 3.10, TRAP 5) — that setting is console-only.

## Controls Requiring Manual Steps

- **1.1 SAML SSO** — Organization Settings > SSO in the Buildkite UI, or `packs/buildkite/api/hth-buildkite-1.01-configure-saml-sso.sh`.
- **3.3 Agent Infrastructure** — OS hardening and network restrictions on the agent hosts themselves; see the `config/` packs.
- **3.10 "Require templates" org strictness** — console only, no API surface.
- **4.1 Audit log review** — enabled by default; review via Organization Settings > Audit Log.

## Files

| File | Purpose |
|------|---------|
| `providers.tf` | Buildkite provider configuration and version floor |
| `variables.tf` | All input variables. Every resource-creating map defaults to `{}` |
| `outputs.tf` | Resource IDs and hardening summary, read from the resources rather than from `profile_level` |
| `terraform.tfvars.example` | Example values. Resource-creating maps are empty or commented out on purpose |
| `hth-buildkite-*.tf` | Individual hardening controls, one file per control |

## Outputs

```bash
terraform output hardening_summary
```

Key outputs include team IDs, pipeline slugs and webhook URLs (sensitive), agent token values (sensitive — returned by the create call only, pipe them straight into a secret manager) and cluster IDs/UUIDs.

## References

- [Buildkite Terraform Provider](https://registry.terraform.io/providers/buildkite/buildkite/latest/docs)
- [Buildkite Security Controls](https://buildkite.com/docs/pipelines/best-practices/security-controls)
- [Buildkite Team Permissions](https://buildkite.com/docs/team-management/permissions)
- [Buildkite Agent Security](https://buildkite.com/docs/agent/v3/securing)
- [How to Harden - Buildkite Guide](https://howtoharden.com/guides/buildkite/)
