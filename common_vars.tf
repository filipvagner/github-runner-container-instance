variable "location" {
  type        = string
  description = "Azure region where the resource should be deployed."
  nullable    = false
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "log_analytics_workspace_name" {
  type        = string
  description = "Name of the resource group"
}

variable "log_analytics_workspace_internet_ingestion_enabled" {
  type        = bool
  default     = true
  description = "(Optional) Should internet ingestion be enabled for the Log Analytics Workspace."
}

variable "log_analytics_workspace_internet_query_enabled" {
  type        = bool
  default     = true
  description = "(Optional) Should internet query be enabled for the Log Analytics Workspace."
}

variable "user_assigned_identity_name" {
  type        = string
  default     = null
  description = "(Optional) The resource ID of the user assigned managed identity."
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}

variable "user_assigned_managed_identity_principal_id" {
  type        = string
  default     = null
  description = "The principal id of the user assigned managed identity. Only required if `user_assigned_managed_identity_creation_enabled == false`."
}
