variable "name" {
  description = "Base name used to compose resource names (e.g. workflo-dev)."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to create the network in."
  type        = string
}

variable "address_space" {
  description = "VNet CIDR address space."
  type        = list(string)
  default     = ["10.20.0.0/16"]
}

variable "aks_subnet_prefixes" {
  description = "Address prefixes for the AKS subnet."
  type        = list(string)
  default     = ["10.20.1.0/24"]
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
