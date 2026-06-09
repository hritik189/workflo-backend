variable "name" {
  description = "ACR name — globally unique, 5-50 alphanumeric chars (no hyphens)."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to create the registry in."
  type        = string
}

variable "sku" {
  description = "ACR SKU (Basic, Standard, Premium)."
  type        = string
  default     = "Standard"
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
