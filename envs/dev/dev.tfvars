prefix = "demo"
env    = "dev"
region = "swedencentral"

tags = {
  env         = "dev"
  owner       = "michal"
  cost_center = "lab"
  region      = "swedencentral"
  project     = "storage-demo"
}

vnet_address_space = ["10.10.0.0/16"]

#############################################
# Storage — dev: cheap, public, minimal rules
#############################################

storage_replication_type = "LRS"
enable_private_endpoint  = false
storage_network_rules    = null # No restrictions in dev

storage_containers = {
  artifacts = { access_type = "private" }
  uploads   = { access_type = "private" }
  temp      = { access_type = "private" }
}

lifecycle_rules = [
  {
    name         = "cleanup-temp"
    prefix_match = ["temp/"]
    # Only delete — no tiering needed for short-lived data.
    tier_to_cool_after_days    = null
    tier_to_archive_after_days = null
    delete_after_days          = 7
  }
]
