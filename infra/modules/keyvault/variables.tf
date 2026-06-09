variable "name" {
  description = "Key Vault name — globally unique, 3-24 alphanumeric/hyphen chars."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to create the vault in."
  type        = string
}

variable "tenant_id" {
  description = "Azure AD tenant ID (from azurerm_client_config)."
  type        = string
}

variable "purge_protection_enabled" {
  description = "Enable purge protection. Recommended true for prod; false in dev for easy teardown."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
