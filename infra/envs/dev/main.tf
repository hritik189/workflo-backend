# dev is a thin wrapper over the shared stack module. Environment-specific sizing is set here;
# everything else uses the stack defaults.
module "stack" {
  source = "../../stack"

  environment = var.environment
  location    = var.location

  acr_name            = var.acr_name
  key_vault_name      = var.key_vault_name
  cosmos_account_name = var.cosmos_account_name
  ai_language_name    = var.ai_language_name

  # dev sizing (small/cheap)
  node_vm_size   = var.node_vm_size
  node_min_count = var.node_min_count
  node_max_count = var.node_max_count

  alert_email           = var.alert_email
  jwt_secret            = var.jwt_secret
  monthly_budget_amount = 50
}
