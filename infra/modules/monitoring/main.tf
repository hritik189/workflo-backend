# Central Log Analytics workspace — sink for Container Insights (AKS) and
# Application Insights (app telemetry). Single workspace keeps logs/metrics queryable together.
resource "azurerm_log_analytics_workspace" "this" {
  name                = "log-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.retention_in_days
  tags                = var.tags
}

# Application Insights in "workspace-based" mode (data lands in Log Analytics).
resource "azurerm_application_insights" "this" {
  name                = "appi-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.this.id
  application_type    = "Node.JS"
  tags                = var.tags
}
