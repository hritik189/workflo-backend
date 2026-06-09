output "endpoint" {
  description = "Language service endpoint URL."
  value       = azurerm_cognitive_account.language.endpoint
}

output "primary_access_key" {
  description = "Primary API key — stored in Key Vault for the task-insights service."
  value       = azurerm_cognitive_account.language.primary_access_key
  sensitive   = true
}
