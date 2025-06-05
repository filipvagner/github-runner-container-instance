variable "location" {
  type        = string
  description = "Azure region where the resource should be deployed."
  nullable    = false
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}

variable "container_registry_name" {
  type        = string
  description = "The name of the container registry"
}

variable "container_registry_private_dns_zone_id" {
  type        = string
  default     = null
  description = "The id of the private DNS zone to create for the container registry. Only required if `container_registry_private_dns_zone_creation_enabled` is `false`."
}

variable "container_registry_subnet_id" {
  type        = string
  default     = null
  description = "The id of the subnet to use for the private endpoint"
}

variable "customer_managed_key" {
  type = object({
    key_vault_resource_id = string
    key_name              = string
    key_version           = optional(string, null)
    user_assigned_identity = optional(object({
      resource_id = string
    }), null)
  })
  default     = null
  description = <<DESCRIPTION
A map of diagnostic settings to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
Controls the Customer managed key configuration on this resource. The following properties can be specified:
- `key_vault_resource_id` - (Required) Resource ID of the Key Vault that the customer managed key belongs to.
- `key_name` - (Required) Specifies the name of the Customer Managed Key Vault Key.
- `key_version` - (Optional) The version of the Customer Managed Key Vault Key.
- `user_assigned_identity` - (Optional) The User Assigned Identity that has access to the key.
  - `resource_id` - (Required) The resource ID of the User Assigned Identity that has access to the key.
DESCRIPTION
}

variable "container_registry_diagnostic_settings" {
  type = map(object({
    name                                     = optional(string, null)
    log_categories                           = optional(set(string), [])
    log_groups                               = optional(set(string), ["allLogs"])
    metric_categories                        = optional(set(string), ["AllMetrics"])
    log_analytics_destination_type           = optional(string, "Dedicated")
    workspace_resource_id                    = optional(string, null)
    storage_account_resource_id              = optional(string, null)
    event_hub_authorization_rule_resource_id = optional(string, null)
    event_hub_name                           = optional(string, null)
    marketplace_partner_resource_id          = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
  A map of diagnostic settings to create on the Container Registry. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
  
  - `name` - (Optional) The name of the diagnostic setting. One will be generated if not set, however this will not be unique if you want to create multiple diagnostic setting resources.
  - `log_categories` - (Optional) A set of log categories to send to the log analytics workspace. Defaults to `[]`.
  - `log_groups` - (Optional) A set of log groups to send to the log analytics workspace. Defaults to `["allLogs"]`.
  - `metric_categories` - (Optional) A set of metric categories to send to the log analytics workspace. Defaults to `["AllMetrics"]`.
  - `log_analytics_destination_type` - (Optional) The destination type for the diagnostic setting. Possible values are `Dedicated` and `AzureDiagnostics`. Defaults to `Dedicated`.
  - `workspace_resource_id` - (Optional) The resource ID of the log analytics workspace to send logs and metrics to.
  - `storage_account_resource_id` - (Optional) The resource ID of the storage account to send logs and metrics to.
  - `event_hub_authorization_rule_resource_id` - (Optional) The resource ID of the event hub authorization rule to send logs and metrics to.
  - `event_hub_name` - (Optional) The name of the event hub. If none is specified, the default event hub will be selected.
  - `marketplace_partner_resource_id` - (Optional) The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic LogsLogs.
  DESCRIPTION
  nullable    = false

  validation {
    condition     = alltrue([for _, v in var.container_registry_diagnostic_settings : contains(["Dedicated", "AzureDiagnostics"], v.log_analytics_destination_type)])
    error_message = "Log analytics destination type must be one of: 'Dedicated', 'AzureDiagnostics'."
  }
  validation {
    condition = alltrue(
      [
        for _, v in var.container_registry_diagnostic_settings :
        v.workspace_resource_id != null || v.storage_account_resource_id != null || v.event_hub_authorization_rule_resource_id != null || v.marketplace_partner_resource_id != null
      ]
    )
    error_message = "At least one of `workspace_resource_id`, `storage_account_resource_id`, `marketplace_partner_resource_id`, or `event_hub_authorization_rule_resource_id`, must be set."
  }
}

variable "enable_trust_policy" {
  type        = bool
  default     = false
  description = "Specified whether trust policy is enabled for this Container Registry."
}

variable "container_registry_lock" {
  type = object({
    kind = string
    name = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
Controls the Resource Lock configuration for this resource. The following properties can be specified:

- `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
- `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
DESCRIPTION

  validation {
    condition     = var.container_registry_lock != null ? contains(["CanNotDelete", "ReadOnly"], var.container_registry_lock.kind) : true
    error_message = "Lock kind must be either `\"CanNotDelete\"` or `\"ReadOnly\"`."
  }
}

variable "managed_identities" {
  type = object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(set(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
Controls the Managed Identity configuration on this resource. The following properties can be specified:

- `system_assigned` - (Optional) Specifies if the System Assigned Managed Identity should be enabled.
- `user_assigned_resource_ids` - (Optional) Specifies a list of User Assigned Managed Identity resource IDs to be assigned to this resource.
DESCRIPTION
  nullable    = false
}

variable "container_registry_private_endpoints" {
  type = map(object({
    name = optional(string, null)
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
      principal_type                         = optional(string, null)
    })), {})
    lock = optional(object({
      kind = string
      name = optional(string, null)
    }), null)
    tags                                    = optional(map(string), null)
    subnet_resource_id                      = string
    private_dns_zone_group_name             = optional(string, "default")
    private_dns_zone_resource_ids           = optional(set(string), [])
    application_security_group_associations = optional(map(string), {})
    private_service_connection_name         = optional(string, null)
    network_interface_name                  = optional(string, null)
    location                                = optional(string, null)
    resource_group_name                     = optional(string, null)
    ip_configurations = optional(map(object({
      name               = string
      private_ip_address = string
    })), {})
  }))
  default     = {}
  description = <<DESCRIPTION
A map of private endpoints to create on the Container Registry. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `name` - (Optional) The name of the private endpoint. One will be generated if not set.
- `role_assignments` - (Optional) A map of role assignments to create on the private endpoint. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time. See `var.role_assignments` for more information.
  - `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
  - `principal_id` - The ID of the principal to assign the role to.
  - `description` - (Optional) The description of the role assignment.
  - `skip_service_principal_aad_check` - (Optional) If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
  - `condition` - (Optional) The condition which will be used to scope the role assignment.
  - `condition_version` - (Optional) The version of the condition syntax. Leave as `null` if you are not using a condition, if you are then valid values are '2.0'.
  - `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created. This field is only used in cross-tenant scenario.
  - `principal_type` - (Optional) The type of the `principal_id`. Possible values are `User`, `Group` and `ServicePrincipal`. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute.
- `lock` - (Optional) The lock level to apply to the private endpoint. Default is `None`. Possible values are `None`, `CanNotDelete`, and `ReadOnly`.
  - `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
  - `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
- `tags` - (Optional) A mapping of tags to assign to the private endpoint.
- `subnet_resource_id` - The resource ID of the subnet to deploy the private endpoint in.
- `private_dns_zone_group_name` - (Optional) The name of the private DNS zone group. One will be generated if not set.
- `private_dns_zone_resource_ids` - (Optional) A set of resource IDs of private DNS zones to associate with the private endpoint. If not set, no zone groups will be created and the private endpoint will not be associated with any private DNS zones. DNS records must be managed external to this module.
- `application_security_group_resource_ids` - (Optional) A map of resource IDs of application security groups to associate with the private endpoint. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
- `private_service_connection_name` - (Optional) The name of the private service connection. One will be generated if not set.
- `network_interface_name` - (Optional) The name of the network interface. One will be generated if not set.
- `location` - (Optional) The Azure location where the resources will be deployed. Defaults to the location of the resource group.
- `resource_group_name` - (Optional) The resource group where the resources will be deployed. Defaults to the resource group of the Container Registry.
- `ip_configurations` - (Optional) A map of IP configurations to create on the private endpoint. If not specified the platform will create one. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
  - `name` - The name of the IP configuration.
  - `private_ip_address` - The private IP address of the IP configuration.
DESCRIPTION
  nullable    = false
}

variable "container_registry_sku" {
  type    = string
  default = "Premium"
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.container_registry_sku)
    error_message = "The SKU name must be either `Basic`, `Standard` or `Premium`."
  }
  description = "The SKU name of the Container Registry. Default is `Premium`. `Possible values are `Basic`, `Standard` and `Premium`."
}

variable "admin_enabled" {
  type        = bool
  default     = false
  description = "Specifies whether the admin user is enabled. Defaults to `false`."
}

variable "public_network_access_enabled" {
  type        = bool
  default     = true
  description = "Specifies whether public access is permitted."
}


variable "quarantine_policy_enabled" {
  type        = bool
  default     = false
  description = "Specifies whether the quarantine policy is enabled."
}

variable "zone_redundancy_enabled" {
  type        = bool
  default     = true
  description = "Specifies whether zone redundancy is enabled.  Modifying this forces a new resource to be created."
}

variable "export_policy_enabled" {
  type        = bool
  default     = true
  description = "Specifies whether export policy is enabled. Defaults to true. In order to set it to false, make sure the public_network_access_enabled is also set to false."
}

variable "anonymous_pull_enabled" {
  type        = bool
  default     = false
  description = "Specifies whether anonymous (unauthenticated) pull access to this Container Registry is allowed.  Requries Standard or Premium SKU."
}

variable "data_endpoint_enabled" {
  type        = bool
  default     = false
  description = "Specifies whether to enable dedicated data endpoints for this Container Registry.  Requires Premium SKU."
}

variable "network_rule_bypass_option" {
  type    = string
  default = "AzureServices"
  validation {
    condition     = var.network_rule_bypass_option == null ? true : contains(["AzureServices", "None"], var.network_rule_bypass_option)
    error_message = "The network_rule_bypass_option variable must be either `AzureServices` or `None`."
  }
  description = <<DESCRIPTION
NOTE: Must be set to AzureServices if variable public_network_access_enabled is set to false.
Specifies whether to allow trusted Azure services access to a network restricted Container Registry.
Possible values are `None` and `AzureServices`. Defaults to `None`.
DESCRIPTION
}

variable "georeplications" {
  type = list(object({
    location                  = string
    regional_endpoint_enabled = optional(bool, true)
    zone_redundancy_enabled   = optional(bool, true)
    tags                      = optional(map(any), null)
  }))
  default     = []
  description = <<DESCRIPTION
A list of geo-replication configurations for the Container Registry.

- `location` - (Required) The geographic location where the Container Registry should be geo-replicated.
- `regional_endpoint_enabled` - (Optional) Enables or disables regional endpoint. Defaults to `true`.
- `zone_redundancy_enabled` - (Optional) Enables or disables zone redundancy. Defaults to `true`.
- `tags` - (Optional) A map of additional tags for the geo-replication configuration. Defaults to `null`.

DESCRIPTION
}

variable "network_rule_set" {
  type = object({
    default_action = optional(string, "Deny")
    ip_rule = optional(list(object({
      # since the `action` property only permits `Allow`, this is hard-coded.
      action   = optional(string, "Allow")
      ip_range = string
    })), [])
  })
  default = null
  validation {
    condition     = var.network_rule_set == null ? true : contains(["Allow", "Deny"], var.network_rule_set.default_action)
    error_message = "The default_action value must be either `Allow` or `Deny`."
  }
  description = <<DESCRIPTION
The network rule set configuration for the Container Registry.
Requires Premium SKU.

- `default_action` - (Optional) The default action when no rule matches. Possible values are `Allow` and `Deny`. Defaults to `Deny`.
- `ip_rules` - (Optional) A list of IP rules in CIDR format. Defaults to `[]`.
  - `action` - Only "Allow" is permitted
  - `ip_range` - The CIDR block from which requests will match the rule.

DESCRIPTION
}

variable "retention_policy_in_days" {
  type        = number
  default     = 7
  description = <<DESCRIPTION
If enabled, this retention policy will purge an untagged manifest after a specified number of days.

- `days` - (Optional) The number of days before the policy Defaults to 7 days.

DESCRIPTION
}

variable "custom_container_registry_images" {
  type = map(object({
    task_name            = string
    dockerfile_path      = string
    context_path         = string
    context_access_token = optional(string, "a") # This `a` is a dummy value because the context_access_token should not be required in the provider
    image_names          = list(string)
  }))
  default     = null
  description = <<DESCRIPTION
The images to build and push to the container registry. This is only relevant if `container_registry_creation_enabled` is `true` and `use_default_container_image` is set to `false`.

- task_name: The name of the task to create for building the image (e.g. `image-build-task`)
- dockerfile_path: The path to the Dockerfile to use for building the image (e.g. `dockerfile`)
- context_path: The path to the context of the Dockerfile in three sections `<repository-url>#<repository-commit>:<repository-folder-path>` (e.g. https://github.com/Azure/avm-container-images-cicd-agents-and-runners#bc4087f:azure-devops-agent)
- context_access_token: The access token to use for accessing the context. Supply a PAT if targetting a private repository.
- image_names: A list of the names of the images to build (e.g. `["image-name:tag"]`)

DESCRIPTION
}

variable "user_assigned_managed_identity_principal_id" {
  type        = string
  default     = null
  description = "The principal id of the user assigned managed identity. Only required if `user_assigned_managed_identity_creation_enabled == false`."
}
