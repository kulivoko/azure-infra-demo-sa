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
