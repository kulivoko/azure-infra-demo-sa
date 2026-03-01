<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 3.112 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 3.112 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_storage"></a> [storage](#module\_storage) | ./modules/storage | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_resource_group.rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_subnet.private_endpoints](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet.workload](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_virtual_network.vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_enable_private_endpoint"></a> [enable\_private\_endpoint](#input\_enable\_private\_endpoint) | Create Private Endpoint + DNS for blob storage. | `bool` | `false` | no |
| <a name="input_env"></a> [env](#input\_env) | Environment identifier (dev, staging, prod). | `string` | n/a | yes |
| <a name="input_lifecycle_rules"></a> [lifecycle\_rules](#input\_lifecycle\_rules) | Blob lifecycle management rules. | <pre>list(object({<br/>    name                       = string<br/>    prefix_match               = list(string)<br/>    tier_to_cool_after_days    = optional(number)<br/>    tier_to_archive_after_days = optional(number)<br/>    delete_after_days          = optional(number)<br/>  }))</pre> | `[]` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | Naming prefix for all resources. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Azure region for resource deployment. | `string` | n/a | yes |
| <a name="input_storage_containers"></a> [storage\_containers](#input\_storage\_containers) | Map of blob containers to create. | <pre>map(object({<br/>    access_type = string<br/>  }))</pre> | n/a | yes |
| <a name="input_storage_network_rules"></a> [storage\_network\_rules](#input\_storage\_network\_rules) | Storage network rules. Null = unrestricted (dev). | <pre>object({<br/>    default_action = string<br/>    ip_rules       = list(string)<br/>    bypass         = list(string)<br/>  })</pre> | `null` | no |
| <a name="input_storage_replication_type"></a> [storage\_replication\_type](#input\_storage\_replication\_type) | Storage account replication: LRS, GRS, ZRS, etc. | `string` | `"LRS"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to all resources for governance. | `map(string)` | n/a | yes |
| <a name="input_vnet_address_space"></a> [vnet\_address\_space](#input\_vnet\_address\_space) | CIDR block(s) for the virtual network. | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_private_endpoint_ip"></a> [private\_endpoint\_ip](#output\_private\_endpoint\_ip) | Private IP of storage PE (null if not enabled). |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | Name of the resource group. |
| <a name="output_storage_account_name"></a> [storage\_account\_name](#output\_storage\_account\_name) | Name of the storage account. |
| <a name="output_storage_containers"></a> [storage\_containers](#output\_storage\_containers) | List of created blob containers. |
| <a name="output_storage_primary_endpoint"></a> [storage\_primary\_endpoint](#output\_storage\_primary\_endpoint) | Primary blob endpoint URL. |
| <a name="output_vnet_id"></a> [vnet\_id](#output\_vnet\_id) | Resource ID of the virtual network. |
<!-- END_TF_DOCS -->