#############################################
# Terraform + Provider
#############################################

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.112"
    }
  }

  # Remote state on Azure Storage with blob lease locking.
  # Backend values injected via -backend-config=envs/<env>/backend.tfbackend
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

#############################################
# Resource Group
#############################################

resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-${var.env}-${var.region}-rg"
  location = var.region
  tags     = var.tags
}

#############################################
# Networking — inline VNet for PE support
#############################################

# Simple VNet with two subnets: workload + private endpoints.
# Kept inline (not a module) because networking is supporting infra here,
# not the primary deliverable. If the project grows, extract to a module.
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-${var.env}-${var.region}-vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.region
  address_space       = var.vnet_address_space
  tags                = var.tags
}

resource "azurerm_subnet" "workload" {
  name                 = "${var.prefix}-${var.env}-workload-snet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [cidrsubnet(var.vnet_address_space[0], 8, 1)]
  service_endpoints    = ["Microsoft.Storage"]
}

resource "azurerm_subnet" "private_endpoints" {
  name                 = "${var.prefix}-${var.env}-pe-snet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [cidrsubnet(var.vnet_address_space[0], 8, 2)]
}

#############################################
# Storage Module
#############################################

module "storage" {
  source = "./modules/storage"

  # Storage account name: alphanumeric, globally unique, max 24 chars.
  name                = replace("${var.prefix}${var.env}${var.region}sa", "-", "")
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.region

  # Account settings — differ between dev (cheap) and prod (resilient).
  replication_type           = var.storage_replication_type
  enable_versioning          = var.env == "prod" ? true : false
  soft_delete_retention_days = var.env == "prod" ? 30 : 7

  # Containers and lifecycle from tfvars.
  containers      = var.storage_containers
  lifecycle_rules = var.lifecycle_rules

  # Network rules: null in dev (public), locked down in prod.
  network_rules = var.storage_network_rules != null ? {
    default_action = var.storage_network_rules.default_action
    ip_rules       = var.storage_network_rules.ip_rules
    subnet_ids     = [azurerm_subnet.workload.id]
    bypass         = var.storage_network_rules.bypass
  } : null

  # Private Endpoint: only in prod.
  private_endpoint = var.enable_private_endpoint ? {
    subnet_id = azurerm_subnet.private_endpoints.id
    vnet_id   = azurerm_virtual_network.vnet.id
  } : null

  tags = var.tags
}
