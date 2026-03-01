<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 3.112 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 3.112 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_private_dns_zone.blob](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) | resource |
| [azurerm_private_dns_zone_virtual_network_link.blob](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_private_endpoint.blob](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_storage_account.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_storage_container.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_container) | resource |
| [azurerm_storage_management_policy.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_management_policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_tier"></a> [account\_tier](#input\_account\_tier) | Performance tier: Standard or Premium. | `string` | `"Standard"` | no |
| <a name="input_containers"></a> [containers](#input\_containers) | Map of blob containers to create, keyed by container name.<br/>Each entry specifies the access level.<br/>Example:<br/>{<br/>  artifacts = { access\_type = "private" }<br/>  logs      = { access\_type = "private" }<br/>} | <pre>map(object({<br/>    access_type = string<br/>  }))</pre> | n/a | yes |
| <a name="input_enable_versioning"></a> [enable\_versioning](#input\_enable\_versioning) | Enable blob versioning for point-in-time recovery. | `bool` | `false` | no |
| <a name="input_lifecycle_rules"></a> [lifecycle\_rules](#input\_lifecycle\_rules) | List of blob lifecycle management rules.<br/>Each rule targets blobs matching prefix\_match and applies tiering/deletion.<br/>Set tier or delete fields to null to skip that action.<br/>Example:<br/>[{<br/>  name                       = "archive-logs"<br/>  prefix\_match               = ["logs/"]<br/>  tier\_to\_cool\_after\_days    = 30<br/>  tier\_to\_archive\_after\_days = 90<br/>  delete\_after\_days          = 365<br/>}] | <pre>list(object({<br/>    name                       = string<br/>    prefix_match               = list(string)<br/>    tier_to_cool_after_days    = optional(number)<br/>    tier_to_archive_after_days = optional(number)<br/>    delete_after_days          = optional(number)<br/>  }))</pre> | `[]` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region (e.g., swedencentral, westeurope). | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Storage account name (3-24 lowercase alphanumerics, globally unique). | `string` | n/a | yes |
| <a name="input_network_rules"></a> [network\_rules](#input\_network\_rules) | Network access restrictions. Set to null for unrestricted access (dev).<br/>Example:<br/>{<br/>  default\_action = "Deny"<br/>  ip\_rules       = ["203.0.113.0/24"]<br/>  subnet\_ids     = []<br/>  bypass         = ["AzureServices"]<br/>} | <pre>object({<br/>    default_action = string<br/>    ip_rules       = list(string)<br/>    subnet_ids     = list(string)<br/>    bypass         = list(string)<br/>  })</pre> | `null` | no |
| <a name="input_private_endpoint"></a> [private\_endpoint](#input\_private\_endpoint) | Private Endpoint configuration. Set to null to skip (dev).<br/>Creates PE + Private DNS zone + VNet link for blob sub-resource.<br/>Example:<br/>{<br/>  subnet\_id = "/subscriptions/.../subnets/pe-snet"<br/>  vnet\_id   = "/subscriptions/.../virtualNetworks/my-vnet"<br/>} | <pre>object({<br/>    subnet_id = string<br/>    vnet_id   = string<br/>  })</pre> | `null` | no |
| <a name="input_replication_type"></a> [replication\_type](#input\_replication\_type) | Replication strategy: LRS, GRS, ZRS, GZRS, RA-GRS, RA-GZRS. | `string` | `"LRS"` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group to deploy into. | `string` | n/a | yes |
| <a name="input_soft_delete_retention_days"></a> [soft\_delete\_retention\_days](#input\_soft\_delete\_retention\_days) | Days to retain soft-deleted blobs and containers (1-365). | `number` | `7` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to all resources. Must include: env, owner, cost\_center, region. | `map(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_container_names"></a> [container\_names](#output\_container\_names) | List of created container names. |
| <a name="output_primary_access_key"></a> [primary\_access\_key](#output\_primary\_access\_key) | Primary access key (sensitive). |
| <a name="output_primary_blob_endpoint"></a> [primary\_blob\_endpoint](#output\_primary\_blob\_endpoint) | Primary blob service endpoint URL. |
| <a name="output_private_endpoint_ip"></a> [private\_endpoint\_ip](#output\_private\_endpoint\_ip) | Private IP of the blob PE (null if PE not enabled). |
| <a name="output_storage_account_id"></a> [storage\_account\_id](#output\_storage\_account\_id) | Resource ID of the storage account. |
| <a name="output_storage_account_name"></a> [storage\_account\_name](#output\_storage\_account\_name) | Name of the storage account. |
<!-- END_TF_DOCS -->