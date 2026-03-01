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
<!-- END_TF_DOCS -->
