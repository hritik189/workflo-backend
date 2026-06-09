variable "environment" {
  description = "Environment name (dev/staging/prod) — used in resource names and tags."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "eastus"
}

variable "tags" {
  description = "Extra tags merged onto the defaults."
  type        = map(string)
  default     = {}
}

# --- Globally-unique resource names ---
variable "acr_name" {
  type        = string
  description = "ACR name (5-50 alphanumeric, globally unique)."
}

variable "acr_sku" {
  type    = string
  default = "Standard"
}

variable "key_vault_name" {
  type        = string
  description = "Key Vault name (3-24 chars, globally unique)."
}

variable "key_vault_purge_protection" {
  type    = bool
  default = false
}

variable "cosmos_account_name" {
  type        = string
  description = "Cosmos DB account name (3-44 lowercase, globally unique)."
}

variable "ai_language_name" {
  type        = string
  description = "Azure AI Language account name (globally unique)."
}

variable "ai_language_sku" {
  type    = string
  default = "S"
}

# --- AKS ---
variable "kubernetes_version" {
  type    = string
  default = null
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

# --- Monitoring ---
variable "log_retention_days" {
  type    = number
  default = 30
}

variable "alert_email" {
  type        = string
  description = "Email address that receives monitoring and budget alerts."
}

# --- Workload identity bindings (must match the Helm ServiceAccounts) ---
variable "k8s_namespace" {
  type    = string
  default = "workflo"
}

variable "api_service_account_name" {
  type    = string
  default = "workflo-api"
}

variable "task_insights_service_account_name" {
  type    = string
  default = "workflo-task-insights"
}

# --- FinOps ---
variable "monthly_budget_amount" {
  type        = number
  description = "Monthly cost budget for the environment, in subscription currency."
  default     = 50
}

variable "budget_start_date" {
  type        = string
  description = "Budget start date (must be the first day of a month, RFC3339)."
  default     = "2026-06-01T00:00:00Z"
}

# --- Secrets (never commit; supply via TF_VAR_jwt_secret) ---
variable "jwt_secret" {
  type        = string
  sensitive   = true
  description = "JWT signing secret, stored in Key Vault as JWT-SECRET."
}
