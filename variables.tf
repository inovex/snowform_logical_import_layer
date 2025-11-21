variable "resource_type" {
  type        = string
  default     = "view"
  description = "Type of logical layer resource to create. Use 'view' for simple pass-through or 'dynamic_table' for materialized, auto-refreshing data."

  validation {
    condition     = contains(["view", "dynamic_table"], var.resource_type)
    error_message = "The resource_type must be either 'view' or 'dynamic_table'."
  }
}

variable "procedure_database" {
  type        = string
  description = "The Snowflake database where the view creation stored procedure will be deployed. This database must already exist."

  validation {
    condition     = var.procedure_database != null && length(var.procedure_database) > 0
    error_message = "The procedure_database must be a non-empty string."
  }
}

variable "procedure_schema" {
  type        = string
  description = "The Snowflake schema where the view creation stored procedure will be deployed. This schema must already exist."

  validation {
    condition     = var.procedure_schema != null && length(var.procedure_schema) > 0
    error_message = "The procedure_schema must be a non-empty string."
  }
}

variable "source_to_target_mappings" {
  type = map(object({
    target_database = string
    target_schema   = string
    target_name     = string
  }))
  description = <<-EOT
    Map of source objects to target logical layer objects. The key is the fully qualified source name,
    and the value is an object containing target location details.
    
    Example:
    {
      "SOURCE_DB.SOURCE_SCHEMA.SOURCE_TABLE" = {
        target_database = "LOGICAL_DB"
        target_schema   = "LOGICAL_SCHEMA"
        target_name     = "LOGICAL_VIEW_NAME"
      }
    }
  EOT

  validation {
    condition = alltrue([
      for source, target in var.source_to_target_mappings :
      length(split(".", source)) == 3
    ])
    error_message = "All source keys must be fully qualified names in the format 'DATABASE.SCHEMA.OBJECT'."
  }

  validation {
    condition = alltrue([
      for target in values(var.source_to_target_mappings) :
      target.target_database != null && target.target_schema != null && target.target_name != null
    ])
    error_message = "All target mappings must specify target_database, target_schema, and target_name."
  }
}

variable "database_role_grants" {
  type        = map(list(string))
  description = <<-EOT
    Map of target databases to lists of Snowflake roles that should receive read access.
    Roles will be granted USAGE on database and schemas, plus SELECT on all current and future views.
    
    Example:
    {
      "LOGICAL_DB" = ["DATA_ANALYST_ROLE", "DATA_ENGINEER_ROLE"]
    }
  EOT

  validation {
    condition = alltrue([
      for db, roles in var.database_role_grants :
      length(roles) > 0
    ])
    error_message = "Each database must have at least one role assigned."
  }
}

variable "dynamic_table_warehouse" {
  type        = string
  default     = null
  description = "The Snowflake warehouse to use for dynamic table refresh operations. Required when resource_type = 'dynamic_table'."

  # validation {
  #   condition     = var.resource_type == "dynamic_table" ? var.dynamic_table_warehouse != null : true
  #   error_message = "The dynamic_table_warehouse is required when resource_type is 'dynamic_table'."
  # }
}

variable "dynamic_table_lag_downstream" {
  type        = bool
  default     = false
  description = "When true, the dynamic table refreshes only when downstream dynamic tables that depend on it are refreshed. Cannot be used with dynamic_table_lag_duration."
}

variable "dynamic_table_lag_duration" {
  type        = string
  default     = null
  description = <<-EOT
    Maximum staleness allowed for the dynamic table. Format: '<number> {seconds|minutes|hours|days}'.
    Minimum value is 60 seconds. If this dynamic table depends on other dynamic tables, this value must be 
    greater than or equal to their target lag. Cannot be used with dynamic_table_lag_downstream.
    
    Examples: "60 seconds", "5 minutes", "2 hours", "1 days"
  EOT

  validation {
    condition = (
      var.dynamic_table_lag_duration == null ||
      can(regex("^[0-9]+ (second|seconds|minute|minutes|hour|hours|day|days)$", var.dynamic_table_lag_duration))
    )
    error_message = "The dynamic_table_lag_duration must be in the format '<number> {seconds|minutes|hours|days}', e.g., '60 seconds' or '2 hours'."
  }

  # validation {
  #   condition     = !(var.dynamic_table_lag_downstream && var.dynamic_table_lag_duration != null)
  #   error_message = "Cannot specify both dynamic_table_lag_downstream and dynamic_table_lag_duration."
  # }
}

locals {
  # Convert source_to_target_mappings to legacy format for backward compatibility
  share_view_mapping_legacy = {
    for source, target in var.source_to_target_mappings :
    source => [target.target_database, target.target_schema, target.target_name]
  }

  # Flatten the database-to-roles mapping for individual grant resources
  # Creates a unique key for each database-role combination
  database_role_combinations = flatten([
    for database, roles in var.database_role_grants : [
      for role in roles : {
        database = database
        role     = role
        key      = "${database}:${role}"
      }
    ]
  ])

  # Convert to map for for_each usage
  database_role_grant_map = {
    for combo in local.database_role_combinations :
    combo.key => {
      database = combo.database
      role     = combo.role
    }
  }
}
