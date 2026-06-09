variable "name" {
  description = "Cognitive account name — globally unique (used as the custom subdomain)."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to create the account in."
  type        = string
}

variable "sku_name" {
  description = "Pricing tier. 'F0' is the free tier (one per subscription); 'S' is standard."
  type        = string
  default     = "S"
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
