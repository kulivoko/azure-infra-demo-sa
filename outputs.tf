output "resource_group_name" {
  description = "Name of the resource group."
  value       = azurerm_resource_group.rg.name
}

output "vnet_id" {
  description = "Resource ID of the virtual network."
  value       = azurerm_virtual_network.vnet.id
}

output "storage_account_name" {
  description = "Name of the storage account."
  value       = module.storage.storage_account_name
}

output "storage_primary_endpoint" {
  description = "Primary blob endpoint URL."
  value       = module.storage.primary_blob_endpoint
}

output "storage_containers" {
  description = "List of created blob containers."
  value       = module.storage.container_names
}

output "private_endpoint_ip" {
  description = "Private IP of storage PE (null if not enabled)."
  value       = module.storage.private_endpoint_ip
}
