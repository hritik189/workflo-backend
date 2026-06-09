variable "subscription_id" {
  description = "Azure subscription ID to deploy into."
  type        = string
}

variable "environment" {
  type    = string
  default = "staging"
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "acr_name" {
  type = string
}

variable "key_vault_name" {
  type = string
}

variable "cosmos_account_name" {
  type = string
}

variable "ai_language_name" {
  type = string
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
  default = 4
}

variable "alert_email" {
  type = string
}

variable "jwt_secret" {
  type      = string
  sensitive = true
}
