# Shared composition for all environments. Each env (dev/staging/prod) is a thin wrapper that
# calls this module with environment-specific values. Provider/backend live in the env dirs.
data "azurerm_client_config" "current" {}

locals {
  name = "workflo-${var.environment}"
  tags = merge({
    project     = "workflo"
    environment = var.environment
    managedBy   = "terraform"
  }, var.tags)
}

resource "azurerm_resource_group" "this" {
  name     = "rg-workflo-${var.environment}"
  location = var.location
  tags     = local.tags
}

module "network" {
  source              = "../modules/network"
  name                = local.name
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

module "monitoring" {
  source              = "../modules/monitoring"
  name                = local.name
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  retention_in_days   = var.log_retention_days
  tags                = local.tags
}

module "acr" {
  source              = "../modules/acr"
  name                = var.acr_name
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = var.acr_sku
  tags                = local.tags
}

module "keyvault" {
  source                   = "../modules/keyvault"
  name                     = var.key_vault_name
  location                 = var.location
  resource_group_name      = azurerm_resource_group.this.name
  tenant_id                = data.azurerm_client_config.current.tenant_id
  purge_protection_enabled = var.key_vault_purge_protection
  tags                     = local.tags
}

module "cosmosdb" {
  source              = "../modules/cosmosdb"
  name                = var.cosmos_account_name
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

module "ai_language" {
  source              = "../modules/ai_language"
  name                = var.ai_language_name
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = var.ai_language_sku
  tags                = local.tags
}

module "aks" {
  source                     = "../modules/aks"
  name                       = local.name
  location                   = var.location
  resource_group_name        = azurerm_resource_group.this.name
  kubernetes_version         = var.kubernetes_version
  subnet_id                  = module.network.aks_subnet_id
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  node_vm_size               = var.node_vm_size
  node_min_count             = var.node_min_count
  node_max_count             = var.node_max_count
  tags                       = local.tags
}

module "alerts" {
  source                  = "../modules/alerts"
  name                    = local.name
  resource_group_name     = azurerm_resource_group.this.name
  location                = var.location
  app_insights_id         = module.monitoring.app_insights_id
  action_group_short_name = "workflo"
  alert_email             = var.alert_email
}

# --- AKS -> ACR: pull images with the kubelet managed identity (no registry creds) ---
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                            = module.acr.acr_id
  role_definition_name             = "AcrPull"
  principal_id                     = module.aks.kubelet_identity_object_id
  skip_service_principal_aad_check = true
}

# --- Workload Identity for the api pod ---
resource "azurerm_user_assigned_identity" "api" {
  name                = "id-workflo-api-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

resource "azurerm_federated_identity_credential" "api" {
  name                = "fic-workflo-api"
  resource_group_name = azurerm_resource_group.this.name
  parent_id           = azurerm_user_assigned_identity.api.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = module.aks.oidc_issuer_url
  subject             = "system:serviceaccount:${var.k8s_namespace}:${var.api_service_account_name}"
}

resource "azurerm_role_assignment" "api_kv_secrets_user" {
  scope                = module.keyvault.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.api.principal_id
}

# --- Workload Identity for the task-insights pod ---
resource "azurerm_user_assigned_identity" "task_insights" {
  name                = "id-workflo-task-insights-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

resource "azurerm_federated_identity_credential" "task_insights" {
  name                = "fic-workflo-task-insights"
  resource_group_name = azurerm_resource_group.this.name
  parent_id           = azurerm_user_assigned_identity.task_insights.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = module.aks.oidc_issuer_url
  subject             = "system:serviceaccount:${var.k8s_namespace}:${var.task_insights_service_account_name}"
}

resource "azurerm_role_assignment" "task_insights_kv_secrets_user" {
  scope                = module.keyvault.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.task_insights.principal_id
}

# The Terraform deployer needs data-plane access to WRITE the secrets below.
resource "azurerm_role_assignment" "deployer_kv_secrets_officer" {
  scope                = module.keyvault.key_vault_id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# --- Application secrets (KV secret names allow only alphanumerics and hyphens) ---
resource "azurerm_key_vault_secret" "db_url" {
  name         = "DB-URL"
  value        = module.cosmosdb.mongodb_connection_string
  key_vault_id = module.keyvault.key_vault_id
  depends_on   = [azurerm_role_assignment.deployer_kv_secrets_officer]
}

resource "azurerm_key_vault_secret" "jwt_secret" {
  name         = "JWT-SECRET"
  value        = var.jwt_secret
  key_vault_id = module.keyvault.key_vault_id
  depends_on   = [azurerm_role_assignment.deployer_kv_secrets_officer]
}

resource "azurerm_key_vault_secret" "ai_language_key" {
  name         = "AI-LANGUAGE-KEY"
  value        = module.ai_language.primary_access_key
  key_vault_id = module.keyvault.key_vault_id
  depends_on   = [azurerm_role_assignment.deployer_kv_secrets_officer]
}

resource "azurerm_key_vault_secret" "appinsights_connection_string" {
  name         = "APPINSIGHTS-CONNECTION-STRING"
  value        = module.monitoring.app_insights_connection_string
  key_vault_id = module.keyvault.key_vault_id
  depends_on   = [azurerm_role_assignment.deployer_kv_secrets_officer]
}

# --- FinOps: monthly cost budget for the environment, alerting the same email ---
resource "azurerm_consumption_budget_resource_group" "this" {
  name              = "budget-workflo-${var.environment}"
  resource_group_id = azurerm_resource_group.this.id

  amount     = var.monthly_budget_amount
  time_grain = "Monthly"

  time_period {
    start_date = var.budget_start_date
  }

  notification {
    enabled        = true
    threshold      = 80
    operator       = "GreaterThanOrEqualTo"
    threshold_type = "Actual"
    contact_emails = [var.alert_email]
  }

  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThanOrEqualTo"
    threshold_type = "Forecasted"
    contact_emails = [var.alert_email]
  }
}
