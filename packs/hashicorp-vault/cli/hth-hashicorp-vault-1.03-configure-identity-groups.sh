#!/usr/bin/env bash
# HTH HashiCorp Vault Control 1.3: Enable Entity and Group Management
# Profile: L2 | NIST: AC-2
# https://howtoharden.com/guides/hashicorp-vault/#13-enable-entity-and-group-management

# HTH Guide Excerpt: begin cli-configure-identity
# Create identity group
vault write identity/group \
    name="platform-team" \
    policies="team-platform" \
    member_entity_ids=""

# Create entity for user
vault write identity/entity \
    name="john.doe@company.com" \
    policies="base"

# Link OIDC alias to entity
vault write identity/entity-alias \
    name="john.doe@company.com" \
    canonical_id="<entity-id>" \
    mount_accessor="<oidc-accessor>"
# HTH Guide Excerpt: end cli-configure-identity
