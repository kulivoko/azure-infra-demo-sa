# Azure Infrastructure — Storage & Data Platform Demo

Production-grade Terraform IaC for Azure Storage with **Private Endpoints**, **lifecycle management**, and **environment-driven configuration**. Demonstrates reusable modules, shift-left governance, and CI/CD with OIDC authentication.

## Key Patterns

- **Reusable Storage module** with dynamic containers, lifecycle policies, network rules, and Private Endpoint + DNS
- **Environment isolation** via separate tfvars and backend configs (dev = cheap/open, prod = secure/resilient)
- **Private Endpoint** with automated DNS — zero-trust blob access in prod
- **Lifecycle management** via dynamic blocks — tiered storage (hot → cool → archive → delete)
- **OIDC-based CI/CD** — secretless GitHub Actions auth with plan-as-PR-comment workflow
- **Tag governance** enforced at plan time via variable validation
- **Naming convention**: `prefix-env-region-resourcetype`

## Structure

```
modules/
  storage/              # Reusable: SA + containers + lifecycle + PE + DNS
envs/
  dev/                  # swedencentral: LRS, public, temp cleanup
  prod/                 # westeurope:    GRS, PE, tiered retention
.github/workflows/
  terraform.yml         # Validate → Plan (PR comment) → Apply per env
  terraform-docs.yml    # Auto-generated module docs
```

## Quickstart

```bash
# Prerequisites: Terraform >= 1.6, Azure CLI
az login

# Deploy dev
terraform init -backend-config=envs/dev/backend.tfbackend
terraform plan -var-file=envs/dev/dev.tfvars -out=plan.tfplan
terraform apply plan.tfplan
```

## CI/CD Pipeline

```
PR opened → validate → plan-dev ──→ plan-prod
                         │ (comment)    │ (comment)
                         ▼              ▼
merge to main → apply-dev ──→ apply-prod (manual approval)
```

1. **Validate**: `fmt -check`, `validate`, TFLint
2. **Plan**: runs per environment, posts diff as PR comment
3. **Apply**: auto on dev after merge, manual approval gate on prod

### Setup

1. Create Azure AD app registration + Federated Credential for GitHub OIDC
2. Grant Contributor on target subscription/resource group
3. Create GitHub Environments: `dev` and `prod`
4. Set per-environment variables: `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`
5. Add required reviewers on `prod` environment

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| Storage module, not VNet module | Data platform is the primary use case; networking is support |
| Inline VNet in root | Two subnets (workload + PE) — too simple for a module |
| `for_each` on containers | Dynamic creation from variable map, same pattern as subnets |
| Lifecycle via `dynamic` blocks | Flexible per-prefix policies without code duplication |
| PE + Private DNS in module | Encapsulates full zero-trust flow: endpoint → DNS zone → VNet link |
| `count` on PE resources | PE only in prod; null check on `var.private_endpoint` |
| `cidrsubnet()` for subnets | Derive subnet CIDRs from VNet CIDR — no manual calculation |
| Network rules as nullable | `null` = unrestricted (dev), object = locked down (prod) |
| Tag validation on module inputs | Fails at `plan` time, not after deploy |

## Environment Comparison

| Aspect | Dev | Prod |
|--------|-----|------|
| Region | swedencentral | westeurope |
| Replication | LRS | GRS |
| Network | Public | Deny + PE |
| Versioning | Off | On |
| Soft delete | 7 days | 30 days |
| Lifecycle | Delete temp after 7d | Cool 30d → Archive 90d → Delete 365d |
| Private Endpoint | No | Yes + Private DNS |

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
