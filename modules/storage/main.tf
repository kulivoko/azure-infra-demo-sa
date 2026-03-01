terraform {
  required_version = ">= 1.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.112"
    }
  }
}

# No provider block here — child modules inherit the provider
# configuration from the calling root module.

#############################################
# Storage Account
#############################################

resource "azurerm_storage_account" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location

  account_tier             = var.account_tier
  account_replication_type = var.replication_type
  min_tls_version          = "TLS1_2"

  # Block anonymous public access to blobs — security baseline.
  allow_nested_items_to_be_public = false

  # Network rules: control who can reach the storage account.
  # In dev we skip this (public access); in prod we lock it down.
  dynamic "network_rules" {
    for_each = var.network_rules != null ? [var.network_rules] : []
    content {
      default_action             = network_rules.value.default_action
      ip_rules                   = network_rules.value.ip_rules
      virtual_network_subnet_ids = network_rules.value.subnet_ids
      bypass                     = network_rules.value.bypass
    }
  }

  # Blob-level data protection: versioning + soft delete.
  blob_properties {
    versioning_enabled = var.enable_versioning

    delete_retention_policy {
      days = var.soft_delete_retention_days
    }

    container_delete_retention_policy {
      days = var.soft_delete_retention_days
    }
  }

  tags = var.tags
}

#############################################
# Blob Containers — dynamic via for_each
#############################################

resource "azurerm_storage_container" "this" {
  for_each = var.containers

  name                  = each.key
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = each.value.access_type
}

#############################################
# Lifecycle Management Policy
#############################################

# Only created when lifecycle rules are defined.
# Dynamic rule blocks allow per-container or per-prefix policies
# (e.g., archive logs after 90 days, delete temp after 7 days).
resource "azurerm_storage_management_policy" "this" {
  count              = length(var.lifecycle_rules) > 0 ? 1 : 0
  storage_account_id = azurerm_storage_account.this.id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      name    = rule.value.name
      enabled = true

      filters {
        prefix_match = rule.value.prefix_match
        blob_types   = ["blockBlob"]
      }

      actions {
        base_blob {
          tier_to_cool_after_days_since_modification_greater_than    = rule.value.tier_to_cool_after_days
          tier_to_archive_after_days_since_modification_greater_than = rule.value.tier_to_archive_after_days
          delete_after_days_since_modification_greater_than          = rule.value.delete_after_days
        }
      }
    }
  }
}

#############################################
# Private Endpoint + Private DNS (prod-only)
#############################################

# Private Endpoint places a NIC in the designated subnet, routing
# traffic to the storage account over the Azure backbone — no public internet.
resource "azurerm_private_endpoint" "blob" {
  count = var.private_endpoint != null ? 1 : 0

  name                = "${var.name}-blob-pe"
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.private_endpoint.subnet_id

  private_service_connection {
    name                           = "${var.name}-blob-psc"
    private_connection_resource_id = azurerm_storage_account.this.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  # Auto-register A record in the private DNS zone so
  # *.blob.core.windows.net resolves to the PE's private IP.
  private_dns_zone_group {
    name                 = "blob-dns-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob[0].id]
  }

  tags = var.tags
}

# Private DNS Zone: overrides public blob.core.windows.net resolution
# inside linked VNets, pointing to the private endpoint IP.
resource "azurerm_private_dns_zone" "blob" {
  count = var.private_endpoint != null ? 1 : 0

  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Link the DNS zone to the VNet so all VMs/services in the VNet
# resolve blob storage via the private endpoint.
resource "azurerm_private_dns_zone_virtual_network_link" "blob" {
  count = var.private_endpoint != null ? 1 : 0

  name                  = "${var.name}-blob-dnslink"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.blob[0].name
  virtual_network_id    = var.private_endpoint.vnet_id
  registration_enabled  = false
  tags                  = var.tags
}
