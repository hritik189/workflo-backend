# Infrastructure (Terraform)

Provisions the Azure platform for Workflo: **AKS, ACR, Cosmos DB (Mongo API), Key Vault,
Log Analytics + Application Insights, Azure AI Language**, plus the role assignments and
Workload Identity federation that tie them together.

```
infra/
├── modules/      # reusable, provider-agnostic building blocks
│   ├── network/      monitoring/   acr/
│   ├── keyvault/     cosmosdb/      ai_language/
│   └── aks/
└── envs/
    └── dev/      # composition for the dev environment (staging/prod added in Phase 5)
```

## Prerequisites

- Terraform >= 1.5, Azure CLI (`az login` to your subscription)
- Provider: `hashicorp/azurerm ~> 3.100`

## 1. Bootstrap remote state (once per subscription)

State lives in Azure Storage with blob-lease locking. Create the backing store once:

```sh
az group create -n rg-tfstate -l eastus
az storage account create -n sttfstateworkflo -g rg-tfstate -l eastus --sku Standard_LRS
az storage container create -n tfstate --account-name sttfstateworkflo
```

Then copy the backend config and fill in your storage account name:

```sh
cd envs/dev
cp backend.hcl.example backend.hcl   # edit storage_account_name
```

## 2. Configure the environment

Edit `envs/dev/dev.tfvars` — set `subscription_id` and the four **globally-unique** names
(`acr_name`, `key_vault_name`, `cosmos_account_name`, `ai_language_name`). Supply the JWT
secret out-of-band so it never lands in a file:

```sh
export TF_VAR_jwt_secret="$(openssl rand -hex 32)"
```

## 3. Plan & apply

```sh
terraform init -backend-config=backend.hcl
terraform fmt -recursive -check
terraform validate
terraform plan  -var-file=dev.tfvars -out=tfplan
terraform apply tfplan
```

## 4. Wire the outputs into the deploy (Phase 3)

After apply, these outputs feed the Helm chart / kubeconfig:

```sh
terraform output -raw aks_get_credentials_cmd   # run it to get kubectl access
terraform output -raw acr_login_server          # -> Helm image.repository
terraform output -raw key_vault_name            # -> SecretProviderClass keyvaultName
terraform output -raw api_identity_client_id    # -> ServiceAccount client-id annotation
terraform output -raw tenant_id                 # -> SecretProviderClass tenantId
```

## Notes

- **Secretless by design:** AKS pulls from ACR via its kubelet managed identity (`AcrPull`);
  the api pod reads Key Vault via Workload Identity + the Secrets Store CSI driver. No registry
  passwords or connection strings live in Kubernetes.
- **Cosmos = Mongo:** `module.cosmosdb` emits a standard MongoDB connection string stored as the
  `DB-URL` secret, so the app code is unchanged.
- The CI/infra pipeline (`pipelines/infra.yml`) runs `fmt`/`validate`/`plan` on PRs and a gated
  `apply` on merge — see Phase 2.
