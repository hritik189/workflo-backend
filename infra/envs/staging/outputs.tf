output "resource_group" { value = module.stack.resource_group }
output "acr_login_server" { value = module.stack.acr_login_server }
output "aks_cluster_name" { value = module.stack.aks_cluster_name }
output "aks_get_credentials_cmd" { value = module.stack.aks_get_credentials_cmd }
output "key_vault_name" { value = module.stack.key_vault_name }
output "api_identity_client_id" { value = module.stack.api_identity_client_id }
output "task_insights_identity_client_id" { value = module.stack.task_insights_identity_client_id }
output "ai_language_endpoint" { value = module.stack.ai_language_endpoint }
output "tenant_id" { value = module.stack.tenant_id }
output "aks_oidc_issuer_url" { value = module.stack.aks_oidc_issuer_url }

output "app_insights_connection_string" {
  value     = module.stack.app_insights_connection_string
  sensitive = true
}
