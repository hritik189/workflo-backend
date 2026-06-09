# Cosmos DB account exposing the MongoDB wire protocol. The app needs no code change —
# its DB_URL just points at the Cosmos connection string instead of a self-hosted Mongo.
resource "azurerm_cosmosdb_account" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  offer_type          = "Standard"
  kind                = "MongoDB"

  capabilities {
    name = "EnableMongo"
  }

  # Return standard Mongo responses instead of 429s when throughput is exceeded.
  capabilities {
    name = "DisableRateLimitingResponses"
  }

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }

  mongo_server_version = var.mongo_server_version

  tags = var.tags
}

# Matches the database name the app hardcodes in dbConnect.ts ("workflo_DB").
resource "azurerm_cosmosdb_mongo_database" "this" {
  name                = var.database_name
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.this.name
  throughput          = var.throughput
}
