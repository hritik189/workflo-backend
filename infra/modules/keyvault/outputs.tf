output "key_vault_id" {
  description = "Resource ID of the Key Vault."
  value       = azurerm_key_vault.this.id
}

output "key_vault_uri" {
  description = "Vault URI (https://<name>.vault.azure.net/)."
  value       = azurerm_key_vault.this.vault_uri
}

output "key_vault_name" {
  description = "Vault name (referenced by the CSI SecretProviderClass)."
  value       = azurerm_key_vault.this.name
}
