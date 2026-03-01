prefix = "infra"
env    = "prod"
region = "westeurope"

tags = {
  env         = "prod"
  owner       = "platform-team"
  cost_center = "infrastructure"
  region      = "westeurope"
  project     = "storage-demo"
}

vnet_address_space = ["10.20.0.0/16"]

#############################################
# Storage — prod: resilient, private, governed
#############################################

storage_replication_type = "GRS"
enable_private_endpoint  = true

storage_network_rules = {
  default_action = "Deny"
  ip_rules       = [] # Add office/VPN CIDRs here
  bypass         = ["AzureServices"]
}

storage_containers = {
  artifacts = { access_type = "private" }
  backups   = { access_type = "private" }
  logs      = { access_type = "private" }
}

lifecycle_rules = [
  {
    # Logs: cool after 30d → archive after 90d → delete after 1 year.
    name                       = "tiered-log-retention"
    prefix_match               = ["logs/"]
    tier_to_cool_after_days    = 30
    tier_to_archive_after_days = 90
    delete_after_days          = 365
  },
  {
    # Artifacts: keep 6 months then clean up.
    name                       = "artifact-cleanup"
    prefix_match               = ["artifacts/"]
    tier_to_cool_after_days    = null
    tier_to_archive_after_days = null
    delete_after_days          = 180
  }
]
