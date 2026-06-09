module "stack" {
  source = "../../stack"

  environment = var.environment
  location    = var.location

  acr_name            = var.acr_name
  key_vault_name      = var.key_vault_name
  cosmos_account_name = var.cosmos_account_name
  ai_language_name    = var.ai_language_name

  node_vm_size   = var.node_vm_size
  node_min_count = var.node_min_count
  node_max_count = var.node_max_count

  # prod hardening
  key_vault_purge_protection = true
  acr_sku                    = "Premium"
  log_retention_days         = 90

  alert_email           = var.alert_email
  jwt_secret            = var.jwt_secret
  monthly_budget_amount = 300
}
