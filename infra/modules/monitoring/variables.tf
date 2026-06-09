variable "name" {
  description = "Base name used to compose resource names."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to create monitoring resources in."
  type        = string
}

variable "retention_in_days" {
  description = "Log Analytics retention period."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
