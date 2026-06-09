# Private container registry. admin_enabled=false — AKS pulls via its kubelet
# managed identity (AcrPull role assigned in the environment composition), no static creds.
resource "azurerm_container_registry" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  admin_enabled       = false
  tags                = var.tags
}
