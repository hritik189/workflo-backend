# Key Vault with RBAC authorization (no access policies). Roles are granted in the
# environment composition: the deployer gets "Secrets Officer" to write secrets, and
# the api workload identity gets "Secrets User" to read them via the CSI driver.
resource "azurerm_key_vault" "this" {
  name                       = var.name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = var.tenant_id
  sku_name                   = "standard"
  enable_rbac_authorization  = true
  purge_protection_enabled   = var.purge_protection_enabled
  soft_delete_retention_days = 7
  tags                       = var.tags
}
