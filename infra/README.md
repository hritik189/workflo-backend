# infra — Terraform (Azure)

Provisions the entire Azure platform: **AKS, ACR, Cosmos DB (Mongo API), Key Vault, Log Analytics
+ Application Insights, Azure AI Language**, plus the role assignments, Workload Identity
federation, alerts, and cost budget that tie it together.

- [Layout](#layout)
- [How it's organized (modules → stack → envs)](#how-its-organized)
- [Prerequisites](#prerequisites)
- [Step 1 — Bootstrap remote state](#step-1--bootstrap-remote-state)
- [Step 2 — Configure your environment](#step-2--configure-your-environment)
- [Step 3 — Plan & apply](#step-3--plan--apply)
- [Step 4 — Use the outputs](#step-4--use-the-outputs)
- [Module reference](#module-reference)
- [Environments](#environments)
- [Teardown](#teardown)
- [Notes](#notes)

## Layout

```
infra/
├── modules/      # reusable building blocks
│   ├── network/      acr/        aks/
│   ├── keyvault/     cosmosdb/   ai_language/
│   └── monitoring/   alerts/
├── stack/        # shared composition: wires the modules + identities + secrets + budget
└── envs/
    ├── dev/      # thin wrapper: provider + backend + module "stack" + dev.tfvars
    ├── staging/
    └── prod/
```

## How it's organized

The composition lives **once** in `stack/`. Each environment under `envs/` is a thin wrapper that
calls `module "stack"` with environment-specific values, so dev/staging/prod stay in sync and
there's no copy-pasted infrastructure. You always run Terraform from inside an env directory.

## Prerequisites

- Terraform **≥ 1.5**, Azure CLI (`az login` into your subscription)
- Provider: `hashicorp/azurerm ~> 3.100`
- Permissions to create resource groups, role assignments, and Key Vault secrets

## Step 1 — Bootstrap remote state

State is stored in Azure Storage with blob-lease locking. Create the backing store **once** per
subscription:

```sh
az group create -n rg-tfstate -l eastus
az storage account create -n sttfstateworkflo -g rg-tfstate -l eastus --sku Standard_LRS
az storage container create -n tfstate --account-name sttfstateworkflo
```

Then create your backend config (kept out of git):

```sh
cd envs/dev
cp backend.hcl.example backend.hcl     # edit storage_account_name to match yours
```

## Step 2 — Configure your environment

Edit `envs/dev/dev.tfvars`:

- `subscription_id` — your subscription
- `acr_name`, `key_vault_name`, `cosmos_account_name`, `ai_language_name` — **globally unique**
- `alert_email` — where alerts go

Supply the JWT secret out-of-band so it never lands in a file:

```sh
export TF_VAR_jwt_secret="$(openssl rand -hex 32)"
```

## Step 3 — Plan & apply

```sh
terraform init -backend-config=backend.hcl
terraform fmt -recursive -check
terraform validate
terraform plan  -var-file=dev.tfvars -out=tfplan
terraform apply tfplan
```

## Step 4 — Use the outputs

The outputs feed the Helm deploy and your kubeconfig:

```sh
terraform output -raw aks_get_credentials_cmd          # run it to get kubectl access
terraform output -raw acr_login_server                 # -> image repository prefix
terraform output -raw key_vault_name                   # -> Helm keyVault.name
terraform output -raw tenant_id                        # -> Helm keyVault.tenantId
terraform output -raw api_identity_client_id           # -> api ServiceAccount client-id
terraform output -raw task_insights_identity_client_id # -> task-insights ServiceAccount client-id
terraform output -raw ai_language_endpoint             # -> task-insights AI_LANGUAGE_ENDPOINT
```

Continue with [deploy/README.md](../deploy/README.md).

## Module reference

| Module | Creates | Key outputs |
|---|---|---|
| `network` | VNet + AKS subnet | `aks_subnet_id` |
| `acr` | Container registry (admin disabled) | `acr_id`, `login_server` |
| `aks` | AKS (Workload Identity, Container Insights, Key Vault CSI addon, autoscaling) | `oidc_issuer_url`, `kubelet_identity_object_id` |
| `cosmosdb` | Cosmos DB for MongoDB + database | `mongodb_connection_string` |
| `keyvault` | RBAC-authorized Key Vault | `key_vault_id`, `key_vault_name` |
| `ai_language` | Azure AI Language account | `endpoint`, `primary_access_key` |
| `monitoring` | Log Analytics + App Insights | `app_insights_connection_string`, `app_insights_id` |
| `alerts` | Action group + response-time & 5xx alerts | `action_group_id` |

## Environments

Same topology everywhere; only sizing/hardening differ (set in each env's `main.tf`/`tfvars`):

| Env | Nodes | ACR | Log retention | Key Vault purge protection | Budget |
|---|---|---|---|---|---|
| dev | B-series, 1–3 | Standard | 30 days | off | low |
| staging | 1–4 | Standard | 30 days | off | mid |
| prod | D-series, 2–5 | Premium | 90 days | on | higher |

Run each env from its own directory with its own `backend.hcl` and `<env>.tfvars`.

## Teardown

```sh
terraform destroy -var-file=dev.tfvars
```

(Prod has Key Vault purge protection enabled, so a destroyed prod vault is retained for the
soft-delete window.)

## Notes

- `terraform`, `helm`, `az`, `kubectl` were not available where this was authored — run
  `terraform validate`/`plan` yourself before applying.
- The provider is pinned to `azurerm ~> 3.100`. An IDE validating against 4.x may flag
  `resource_group_name`/`parent_id` on the federated credential as deprecated; that's expected and
  not an error on the pinned version.
