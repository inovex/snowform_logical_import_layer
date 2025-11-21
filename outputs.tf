output "procedure_qualified_name" {
  description = "Fully qualified name of the stored procedure used to create views with comments"
  value       = "${var.procedure_database}.${var.procedure_schema}.${snowflake_procedure_python.view_with_comments_creator.name}"
}

output "created_views" {
  description = "Map of created logical layer views with their fully qualified names"
  value = var.resource_type == "view" ? {
    for key, value in local.share_view_mapping_legacy :
    key => "${value[0]}.${value[1]}.${value[2]}"
  } : {}
}

output "created_dynamic_tables" {
  description = "Map of created logical layer dynamic tables with their fully qualified names"
  value = var.resource_type == "dynamic_table" ? {
    for key, value in local.share_view_mapping_legacy :
    key => "${value[0]}.${value[1]}.${value[2]}"
  } : {}
}

output "granted_databases" {
  description = "List of unique databases that have been granted access to roles"
  value       = distinct([for combo in local.database_role_combinations : combo.database])
}

output "granted_roles" {
  description = "List of unique roles that have been granted access to roles"
  value       = distinct([for combo in local.database_role_combinations : combo.role])
}

output "database_role_grants" {
  description = "Map showing which roles have access to which databases"
  value       = var.database_role_grants
}

output "resource_type" {
  description = "The type of resources created (view or dynamic_table)"
  value       = var.resource_type
}
