variable "prefix" {
  type        = string
  description = "Naming prefix for all resources."
}

variable "env" {
  type        = string
  description = "Environment identifier (dev, staging, prod)."

  validation {
    condition     = contains(["dev", "staging", "prod"], var.env)
    error_message = "env must be one of: dev, staging, prod."
  }
}

variable "region" {
  type        = string
  description = "Azure region for resource deployment."
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources for governance."

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

#############################################
# Networking
#############################################

variable "vnet_address_space" {
  type        = list(string)
  description = "CIDR block(s) for the virtual network."
}

#############################################
# Storage
#############################################

variable "storage_replication_type" {
  type        = string
  default     = "LRS"
  description = "Storage account replication: LRS, GRS, ZRS, etc."
}

variable "storage_containers" {
  type = map(object({
    access_type = string
  }))
  description = "Map of blob containers to create."
}

variable "lifecycle_rules" {
  type = list(object({
    name                       = string
    prefix_match               = list(string)
    tier_to_cool_after_days    = optional(number)
    tier_to_archive_after_days = optional(number)
    delete_after_days          = optional(number)
  }))
  default     = []
  description = "Blob lifecycle management rules."
}

variable "storage_network_rules" {
  type = object({
    default_action = string
    ip_rules       = list(string)
    bypass         = list(string)
  })
  default     = null
  description = "Storage network rules. Null = unrestricted (dev)."
}

variable "enable_private_endpoint" {
  type        = bool
  default     = false
  description = "Create Private Endpoint + DNS for blob storage."
}
