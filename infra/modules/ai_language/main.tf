# Azure AI Language (Cognitive Services "TextAnalytics" kind) — backend for the
# task-insights microservice (summarization / sentiment / key-phrase extraction).
# custom_subdomain_name is required for Entra ID (token) auth against the endpoint.
resource "azurerm_cognitive_account" "language" {
  name                  = var.name
  location              = var.location
  resource_group_name   = var.resource_group_name
  kind                  = "TextAnalytics"
  sku_name              = var.sku_name
  custom_subdomain_name = var.name
  tags                  = var.tags
}
