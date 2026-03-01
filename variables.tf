variable "name" {
  type        = string
  description = "Storage account name (3-24 lowercase alphanumerics, globally unique)."

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.name))
    error_message = "Storage account name must be 3-24 lowercase alphanumerics."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group to deploy into."
}

variable "location" {
  type        = string
  description = "Azure region (e.g., swedencentral, westeurope)."
}

#############################################
# Account configuration
#############################################

variable "account_tier" {
  type        = string
  default     = "Standard"
  description = "Performance tier: Standard or Premium."

  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "account_tier must be Standard or Premium."
  }
}

variable "replication_type" {
  type        = string
  default     = "LRS"
  description = "Replication strategy: LRS, GRS, ZRS, GZRS, RA-GRS, RA-GZRS."

  validation {
    condition     = contains(["LRS", "GRS", "ZRS", "GZRS", "RA-GRS", "RA-GZRS"], var.replication_type)
    error_message = "Invalid replication type."
  }
}

variable "enable_versioning" {
  type        = bool
  default     = false
  description = "Enable blob versioning for point-in-time recovery."
}

variable "soft_delete_retention_days" {
  type        = number
  default     = 7
  description = "Days to retain soft-deleted blobs and containers (1-365)."

  validation {
    condition     = var.soft_delete_retention_days >= 1 && var.soft_delete_retention_days <= 365
    error_message = "soft_delete_retention_days must be between 1 and 365."
  }
}

#############################################
# Containers
#############################################

variable "containers" {
  description = <<-EOT
    Map of blob containers to create, keyed by container name.
    Each entry specifies the access level.
    Example:
    {
      artifacts = { access_type = "private" }
      logs      = { access_type = "private" }
    }
  EOT
  type = map(object({
    access_type = string
  }))

  validation {
    condition = alltrue([
      for c in values(var.containers) : contains(["private", "blob", "container"], c.access_type)
    ])
    error_message = "container access_type must be: private, blob, or container."
  }
}

#############################################
# Lifecycle rules
#############################################

variable "lifecycle_rules" {
  description = <<-EOT
    List of blob lifecycle management rules.
    Each rule targets blobs matching prefix_match and applies tiering/deletion.
    Set tier or delete fields to null to skip that action.
    Example:
    [{
      name                       = "archive-logs"
      prefix_match               = ["logs/"]
      tier_to_cool_after_days    = 30
      tier_to_archive_after_days = 90
      delete_after_days          = 365
    }]
  EOT
  type = list(object({
    name                       = string
    prefix_match               = list(string)
    tier_to_cool_after_days    = optional(number)
    tier_to_archive_after_days = optional(number)
    delete_after_days          = optional(number)
  }))
  default = []
}

#############################################
# Network rules
#############################################

variable "network_rules" {
  description = <<-EOT
    Network access restrictions. Set to null for unrestricted access (dev).
    Example:
    {
      default_action = "Deny"
      ip_rules       = ["203.0.113.0/24"]
      subnet_ids     = []
      bypass         = ["AzureServices"]
    }
  EOT
  type = object({
    default_action = string
    ip_rules       = list(string)
    subnet_ids     = list(string)
    bypass         = list(string)
  })
  default = null
}

#############################################
# Private Endpoint
#############################################

variable "private_endpoint" {
  description = <<-EOT
    Private Endpoint configuration. Set to null to skip (dev).
    Creates PE + Private DNS zone + VNet link for blob sub-resource.
    Example:
    {
      subnet_id = "/subscriptions/.../subnets/pe-snet"
      vnet_id   = "/subscriptions/.../virtualNetworks/my-vnet"
    }
  EOT
  type = object({
    subnet_id = string
    vnet_id   = string
  })
  default = null
}

#############################################
# Tags
#############################################

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources. Must include: env, owner, cost_center, region."

  validation {
    condition = alltrue([
      contains(keys(var.tags), "env"),
      contains(keys(var.tags), "owner"),
      contains(keys(var.tags), "cost_center"),
      contains(keys(var.tags), "region"),
    ])
    error_message = "Tags must include: env, owner, cost_center, region."
  }
}
