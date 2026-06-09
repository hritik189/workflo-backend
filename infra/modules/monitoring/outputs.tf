output "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics workspace (used by the AKS oms_agent addon)."
  value       = azurerm_log_analytics_workspace.this.id
}

output "app_insights_id" {
  description = "Application Insights component resource ID (used as the alert scope)."
  value       = azurerm_application_insights.this.id
}

output "app_insights_connection_string" {
  description = "Application Insights connection string for the app's OpenTelemetry exporter."
  value       = azurerm_application_insights.this.connection_string
  sensitive   = true
}

output "app_insights_instrumentation_key" {
  description = "Application Insights instrumentation key (legacy; prefer the connection string)."
  value       = azurerm_application_insights.this.instrumentation_key
  sensitive   = true
}
