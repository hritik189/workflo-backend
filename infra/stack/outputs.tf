output "resource_group" {
  value = azurerm_resource_group.this.name
}

output "acr_login_server" {
  value = module.acr.login_server
}

output "aks_cluster_name" {
  value = module.aks.cluster_name
}

output "aks_get_credentials_cmd" {
  value = "az aks get-credentials --resource-group ${azurerm_resource_group.this.name} --name ${module.aks.cluster_name}"
}

output "key_vault_name" {
  value = module.keyvault.key_vault_name
}

output "api_identity_client_id" {
  description = "Client ID for the api ServiceAccount's workload-identity annotation."
  value       = azurerm_user_assigned_identity.api.client_id
}

output "task_insights_identity_client_id" {
  description = "Client ID for the task-insights ServiceAccount's workload-identity annotation."
  value       = azurerm_user_assigned_identity.task_insights.client_id
}

output "ai_language_endpoint" {
  description = "Azure AI Language endpoint (set as AI_LANGUAGE_ENDPOINT on task-insights)."
  value       = module.ai_language.endpoint
}

output "tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}

output "aks_oidc_issuer_url" {
  value = module.aks.oidc_issuer_url
}

output "app_insights_connection_string" {
  value     = module.monitoring.app_insights_connection_string
  sensitive = true
}
