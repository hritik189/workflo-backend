variable "name" {
  description = "Base name used to compose alert resource names."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group for the alert resources."
  type        = string
}

variable "location" {
  description = "Azure region (required by the scheduled query rule)."
  type        = string
}

variable "app_insights_id" {
  description = "Application Insights component resource ID (alert scope)."
  type        = string
}

variable "action_group_short_name" {
  description = "Action group short name (<= 12 chars)."
  type        = string
  default     = "workflo"
}

variable "alert_email" {
  description = "Email address that receives alert notifications."
  type        = string
}

variable "response_time_threshold_ms" {
  description = "Average server response time threshold in milliseconds."
  type        = number
  default     = 2000
}

variable "error_count_threshold" {
  description = "Number of 5xx responses in the window that triggers the error-rate alert."
  type        = number
  default     = 5
}
