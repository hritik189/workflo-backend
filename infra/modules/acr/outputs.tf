output "acr_id" {
  description = "Resource ID of the registry (used for the AcrPull role assignment)."
  value       = azurerm_container_registry.this.id
}

output "login_server" {
  description = "Login server hostname, e.g. myregistry.azurecr.io."
  value       = azurerm_container_registry.this.login_server
}
