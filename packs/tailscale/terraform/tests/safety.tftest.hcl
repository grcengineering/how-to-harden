# Provider mocks exercise our opt-in and precondition logic without API calls.
mock_provider "tailscale" {}

run "default_plan_has_no_managed_resources" {
  command = plan
  assert {
    condition = (
      length(tailscale_tailnet_settings.reviewed) == 0 &&
      length(tailscale_device_key.reviewed_expiry) == 0 &&
      length(tailscale_acl.reviewed) == 0 &&
      length(tailscale_device_subnet_routes.reviewed) == 0 &&
      length(tailscale_logstream_configuration.reviewed) == 0 &&
      length(tailscale_dns_configuration.reviewed) == 0 &&
      length(data.tailscale_users.review) == 0 &&
      length(data.tailscale_devices.review) == 0 &&
      length(data.tailscale_acl.review) == 0
    )
    error_message = "Default plan must not manage resources or read inventories."
  }
}

run "dns_requires_l2" {
  command = plan
  variables {
    reviewed_dns_configuration = {
      nameservers = [], split_dns = {}, search_paths = [], override_local_dns = false, magic_dns = true
    }
  }
  expect_failures = [tailscale_dns_configuration.reviewed["dns"]]
}

run "dns_preserves_complete_reviewed_configuration" {
  command = plan
  variables {
    hth_profile_level = 2
    reviewed_dns_configuration = {
      nameservers        = [{ address = "203.0.113.53", use_with_exit_node = false }]
      split_dns          = { "corp.example.com" = [{ address = "10.0.0.53", use_with_exit_node = false }] }
      search_paths       = ["corp.example.com"]
      override_local_dns = true
      magic_dns          = true
    }
  }
  assert {
    condition = (
      one(tailscale_dns_configuration.reviewed["dns"].nameservers).address == "203.0.113.53" &&
      one(tailscale_dns_configuration.reviewed["dns"].split_dns).domain == "corp.example.com" &&
      tailscale_dns_configuration.reviewed["dns"].search_paths == tolist(["corp.example.com"]) &&
      tailscale_dns_configuration.reviewed["dns"].override_local_dns
    )
    error_message = "The plan must retain the complete reviewed DNS configuration."
  }
}

run "invalid_dns_resolver_is_rejected" {
  command = plan
  variables {
    hth_profile_level = 2
    reviewed_dns_configuration = {
      nameservers = [{ address = "https://example.invalid", use_with_exit_node = false }]
      split_dns   = {}, search_paths = [], override_local_dns = true, magic_dns = true
    }
  }
  expect_failures = [var.reviewed_dns_configuration]
}

run "exit_node_dns_requires_client_support_review" {
  command = plan
  variables {
    hth_profile_level = 2
    reviewed_dns_configuration = {
      nameservers = [{ address = "203.0.113.53", use_with_exit_node = true }]
      split_dns   = {}, search_paths = [], override_local_dns = true, magic_dns = true
    }
  }
  expect_failures = [tailscale_dns_configuration.reviewed["dns"]]
}

run "reviewed_exit_node_dns_can_be_planned" {
  command = plan
  variables {
    hth_profile_level                       = 2
    dns_clients_support_exit_node_resolvers = true
    reviewed_dns_configuration = {
      nameservers = [{ address = "203.0.113.53", use_with_exit_node = true }]
      split_dns   = {}, search_paths = [], override_local_dns = true, magic_dns = true
    }
  }
  assert {
    condition     = one(tailscale_dns_configuration.reviewed["dns"].nameservers).use_with_exit_node
    error_message = "Reviewed exit-node resolver selection should reach the planned resource."
  }
}

run "device_approval_requires_lock_check" {
  command = plan
  variables {
    reviewed_tailnet_settings = { devices_approval_on = true }
  }
  expect_failures = [tailscale_tailnet_settings.reviewed["settings"]]
}

run "updates_do_not_require_disabling_lock" {
  command = plan
  variables {
    reviewed_tailnet_settings = { devices_auto_updates_on = true }
  }
  assert {
    condition     = tailscale_tailnet_settings.reviewed["settings"].devices_auto_updates_on
    error_message = "An independent update setting should preserve enrollment choices."
  }
}

run "stopping_flow_logs_still_requires_l2" {
  command = plan
  variables {
    reviewed_tailnet_settings = { network_flow_logging_on = false }
  }
  expect_failures = [tailscale_tailnet_settings.reviewed["settings"]]
}

run "external_tailnet_policy_requires_l2" {
  command = plan
  variables {
    reviewed_tailnet_settings = { users_role_allowed_to_join_external_tailnet = "none" }
  }
  expect_failures = [tailscale_tailnet_settings.reviewed["settings"]]
}

run "invalid_key_duration_is_rejected" {
  command = plan
  variables {
    reviewed_tailnet_settings = { devices_key_duration_days = 181 }
  }
  expect_failures = [var.reviewed_tailnet_settings]
}

run "subnet_routes_require_l2" {
  command = plan
  variables {
    reviewed_subnet_routes = { node123 = ["10.0.0.0/24"] }
  }
  expect_failures = [tailscale_device_subnet_routes.reviewed["node123"]]
}

run "default_exit_route_is_rejected" {
  command = plan
  variables {
    hth_profile_level      = 2
    reviewed_subnet_routes = { node123 = ["0.0.0.0/0"] }
  }
  expect_failures = [var.reviewed_subnet_routes]
}

run "ipv6_default_route_is_rejected" {
  command = plan
  variables {
    hth_profile_level      = 2
    reviewed_subnet_routes = { node123 = ["::/0"] }
  }
  expect_failures = [var.reviewed_subnet_routes]
}

run "valid_subnet_route_can_be_planned" {
  command = plan
  variables {
    hth_profile_level      = 2
    reviewed_subnet_routes = { node123 = ["10.0.0.0/24"] }
  }
  assert {
    condition     = contains(tailscale_device_subnet_routes.reviewed["node123"].routes, "10.0.0.0/24")
    error_message = "The reviewed CIDR must reach the planned resource."
  }
}
