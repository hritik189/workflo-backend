output "mongodb_connection_string" {
  description = "Primary MongoDB connection string — stored in Key Vault as the app's DB_URL."
  value       = azurerm_cosmosdb_account.this.primary_mongodb_connection_string
  sensitive   = true
}

output "account_name" {
  description = "Cosmos DB account name."
  value       = azurerm_cosmosdb_account.this.name
}
