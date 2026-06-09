variable "name" {
  description = "Cosmos DB account name — globally unique, 3-44 lowercase alphanumeric/hyphen chars."
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

variable "database_name" {
  description = "Mongo database name. Must match the app's hardcoded dbName."
  type        = string
  default     = "workflo_DB"
}

variable "mongo_server_version" {
  description = "Mongo wire-protocol version exposed by Cosmos DB."
  type        = string
  default     = "4.2"
}

variable "throughput" {
  description = "Provisioned RU/s for the database (400 is the minimum)."
  type        = number
  default     = 400
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
