# Docker Hub Hardening Code Pack - Terraform

Terraform configuration for applying [Docker Hub hardening controls](https://howtoharden.com/guides/dockerhub/) from the How to Harden project.

## Provider

| Name | Source | Version |
|------|--------|---------|
| docker | docker/docker | ~> 0.3 |

## Profile Levels

| Level | Name | Description |
|-------|------|-------------|
| L1 | Baseline | MFA/SSO enforcement, access tokens, Scout scanning, private repos, audit logging |
| L2 | Hardened | L1 + Docker Content Trust image signing, Dockerfile linting, enhanced monitoring |
| L3 | Maximum Security | L2 + Sigstore/Cosign signing, SLSA provenance attestations |

## Controls

| File | Control | Level |
|------|---------|-------|
| `hth-dockerhub-1.01-enforce-mfa-and-sso.tf` | 1.1 Enforce MFA and SSO | L1 |
| `hth-dockerhub-1.02-implement-access-tokens.tf` | 1.2 Implement Access Tokens | L1 |
| `hth-dockerhub-2.01-enable-docker-scout.tf` | 2.1 Enable Docker Scout | L1 |
| `hth-dockerhub-2.02-image-signing-content-trust.tf` | 2.2 Image Signing (Content Trust) | L2 |
| `hth-dockerhub-3.01-private-repository-configuration.tf` | 3.1 Private Repository Configuration | L1 |
| `hth-dockerhub-3.02-prevent-secret-exposure.tf` | 3.2 Prevent Secret Exposure | L1 |
| `hth-dockerhub-4.01-audit-logging.tf` | 4.1 Audit Logging | L1 |

## Quick Start

```bash
cd packs/dockerhub/terraform/

# Copy and edit variable values
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your Docker Hub org details

# Initialize and apply
terraform init
terraform plan
terraform apply
```

## Apply a Specific Profile Level

```bash
# L1 Baseline (default)
terraform apply -var="profile_level=1"

# L2 Hardened (adds content trust, enhanced monitoring)
terraform apply -var="profile_level=2"

# L3 Maximum Security (adds Cosign, SLSA attestations)
terraform apply -var="profile_level=3"
```

## Authentication

The Docker provider requires a Docker Hub personal access token. Set it via environment variable to avoid committing secrets:

```bash
export TF_VAR_dockerhub_token="dckr_pat_your_token_here"
```

Generate a token at: **Account Settings > Security > Access Tokens**

## Important Notes

- **Business plan required** for SSO enforcement and audit log export features.
- **Docker Content Trust** (L2+) requires Notary key management. Back up your signing keys.
- **Cosign signing** (L3) can use keyless OIDC-based signing for CI/CD pipelines.
- Several controls use `null_resource` with `local-exec` for setup guidance where Docker Hub lacks direct Terraform resource support.
- Token rotation is an operational procedure; Terraform manages initial creation only.

## References

- [Docker Hub Hardening Guide](https://howtoharden.com/guides/dockerhub/)
- [Docker Provider Registry](https://registry.terraform.io/providers/docker/docker/latest/docs)
- [Docker Hub API Reference](https://docs.docker.com/reference/api/hub/latest/)
- [Docker Scout Documentation](https://docs.docker.com/scout/)
- [Docker Content Trust](https://docs.docker.com/engine/security/trust/)
- [Sigstore/Cosign](https://docs.sigstore.dev/)
