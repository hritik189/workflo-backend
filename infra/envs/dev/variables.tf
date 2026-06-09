variable "subscription_id" {
  description = "Azure subscription ID to deploy into."
  type        = string
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "acr_name" {
  description = "ACR name (5-50 alphanumeric, globally unique)."
  type        = string
}

variable "key_vault_name" {
  description = "Key Vault name (3-24 chars, globally unique)."
  type        = string
}

variable "cosmos_account_name" {
  description = "Cosmos DB account name (3-44 lowercase, globally unique)."
  type        = string
}

variable "ai_language_name" {
  description = "Azure AI Language account name (globally unique)."
  type        = string
}

variable "node_vm_size" {
  type    = string
  default = "Standard_B2s"
}

variable "node_min_count" {
  type    = number
  default = 1
}

variable "node_max_count" {
  type    = number
  default = 3
}

variable "alert_email" {
  description = "Email address that receives monitoring and budget alerts."
  type        = string
}

variable "jwt_secret" {
  description = "JWT signing secret (supply via TF_VAR_jwt_secret)."
  type        = string
  sensitive   = true
}
