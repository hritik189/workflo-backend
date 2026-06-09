variable "name" {
  description = "Base name (cluster becomes aks-<name>, dns_prefix is <name>)."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to create the cluster in."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version. Leave null to use the AKS default for the region."
  type        = string
  default     = null
}

variable "subnet_id" {
  description = "Subnet ID for the node pool (from the network module)."
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for Container Insights (oms_agent)."
  type        = string
}

variable "node_vm_size" {
  description = "VM size for the system node pool."
  type        = string
  default     = "Standard_B2s"
}

variable "node_min_count" {
  description = "Minimum nodes (autoscaler floor)."
  type        = number
  default     = 1
}

variable "node_max_count" {
  description = "Maximum nodes (autoscaler ceiling)."
  type        = number
  default     = 3
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
